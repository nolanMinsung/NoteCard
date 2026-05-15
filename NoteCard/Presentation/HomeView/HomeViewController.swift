//
//  HomeViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import Combine
import Data
import Domain
import DesignSystem
import Shared
import UIKit

import Wisp

class HomeViewController: UIViewController {
    
    enum Section: CaseIterable {
        case category
        case favorite
        case all
    }
    
    enum HomeItem: Hashable {
        case category(Domain.Category)
        case memo(MemoHomeUIModel)
        case addCategoryPlaceholder
        case addMemoPlaceholder
    }

    typealias DiffableDataSource = UICollectionViewDiffableDataSource<Section, HomeItem>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, HomeItem>
    typealias CellProvider = DiffableDataSource.CellProvider
    typealias HeaderRegistration = UICollectionView.SupplementaryRegistration<HomeHeaderView>
    typealias CategoryCellRegistration = UICollectionView.CellRegistration<HomeCategoryCell, Domain.Category>
    typealias MemoCellRegistration = UICollectionView.CellRegistration<HomeCardCell, MemoHomeUIModel>
    typealias PlaceholderCellRegistration = UICollectionView.CellRegistration<HomeAddPlaceholderCell, HomeItem>
    
    let sectionHederTitleArray: [String] = [
        L10n.Home.category,
        L10n.Home.favorites,
        L10n.Home.allMemos
    ]
    
    lazy var homeView = HomeView()
    
    var homeCollectionView: WispableCollectionView { self.homeView.homeCollectionView }
    
    private var categories: [Domain.Category] = []
    private var favoriteMemos: [Memo] = []
    private var allMemos: [Memo] = []
    private var diffableDataSource: DiffableDataSource!
    
    private var cancellables: Set<AnyCancellable> = []
    private let coreDataChangePublisher = NotificationCenter.default.publisher(
        for: .NSManagedObjectContextDidSave,
        object: CoreDataStack.shared.backgroundContext
    )
    
    override func loadView() {
        self.view = homeView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNaviBar()
        setupDiffableDataSource()
        Task {
            try await fetchData()
            applySnapshot()
        }
        setupDelegates()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.standardAppearance = {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            return appearance
        }()
        
        self.homeCollectionView.reloadData()
    }
    
    private func setupNaviBar() {
        self.title = L10n.TabBar.home
        
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        
        // 가장 끝까지 스크롤할 때 appearance
        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        scrollEdgeAppearance.backgroundColor = .clear
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.standardAppearance = standardAppearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
        
        self.navigationController?.navigationBar.tintColor = .currentTheme
        self.navigationController?.toolbar.tintColor = .currentTheme
    }
    
    private func fetchData() async throws {
        categories = try await CategoryRepositoryImpl.shared.getAllCategories(
            inOrderOf: .modificationDate,
            isAscending: false
        )
        favoriteMemos = try await MemoEntityRepository.shared.getFavoriteMemos()
        allMemos = try await MemoEntityRepository.shared.getAllMemos()
    }
    
    private func setupDiffableDataSource() {
        let categoryCellRegistration = CategoryCellRegistration { cell, indexPath, category in
            cell.configure(with: category)
        }

        let memoCellRegistration = MemoCellRegistration { cell, indexPath, memoUIModel in
            cell.configure(with: memoUIModel)
        }

        let placeholderCellRegistration = PlaceholderCellRegistration { cell, indexPath, item in
            switch item {
            case .addCategoryPlaceholder:
                // 카테고리 셀은 폭이 좁아 영문 "Add Domain.Category"가 줄바꿈되므로 시각 라벨은 생략하고
                // VoiceOver에만 문구를 노출한다. cornerRadius는 HomeCategoryCell(25)과 동일.
                cell.configure(
                    displayedTitle: nil,
                    accessibilityLabel: L10n.Home.addCategoryPlaceholder,
                    cornerRadius: 25
                )
            case .addMemoPlaceholder:
                // HomeCardCell의 cornerRadius(20)와 동일.
                cell.configure(
                    displayedTitle: L10n.Home.addMemoPlaceholder,
                    accessibilityLabel: L10n.Home.addMemoPlaceholder,
                    cornerRadius: 20
                )
            case .category, .memo:
                // 등록은 placeholder 전용이라 도달 불가.
                break
            }
        }

        let headerViewRegistration = HeaderRegistration.init(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] headerView, elementKind, indexPath in
            guard let self else { return }
            headerView.button.configuration?.baseForegroundColor = UIColor.currentTheme
            // 헤더 안의 버튼은 section 정보를 button의 tag로 저장함.
            headerView.button.tag = indexPath.section
            headerView.button.configuration?.title = self.sectionHederTitleArray[indexPath.section] + " "
            headerView.button.addTarget(self, action: #selector(self.onHeaderButtonTapped), for: .touchUpInside)
        }

        // Cell Provider
        let cellProvider: CellProvider = { collectionView, indexPath, itemIdentifier in
            switch itemIdentifier {
            case .category(let category):
                return collectionView.dequeueConfiguredReusableCell(
                    using: categoryCellRegistration,
                    for: indexPath,
                    item: category)
            case .memo(let memo):
                return collectionView.dequeueConfiguredReusableCell(
                    using: memoCellRegistration,
                    for: indexPath,
                    item: memo
                )
            case .addCategoryPlaceholder, .addMemoPlaceholder:
                return collectionView.dequeueConfiguredReusableCell(
                    using: placeholderCellRegistration,
                    for: indexPath,
                    item: itemIdentifier
                )
            }
        }
        
        // Setting Diffable DataSource
        diffableDataSource = .init(
            collectionView: homeCollectionView,
            cellProvider: cellProvider,
        )
        diffableDataSource.supplementaryViewProvider = {
            collectionView,
            elementKind,
            indexPath in
            guard elementKind == UICollectionView.elementKindSectionHeader else { return nil }
            return collectionView.dequeueConfiguredReusableSupplementary(
                using: headerViewRegistration,
                for: indexPath
            )
        }
    }
    
    private func applySnapshot() {
        var snapshot: Snapshot = .init()
        snapshot.appendSections(Section.allCases)

        if categories.isEmpty {
            snapshot.appendItems([.addCategoryPlaceholder], toSection: .category)
        } else {
            snapshot.appendItems(categories.map({ .category($0) }), toSection: .category)
        }

        snapshot.appendItems(favoriteMemos.map({ .memo(MemoHomeUIModel(memo: $0, section: .favorite)) }), toSection: .favorite)

        if allMemos.isEmpty {
            snapshot.appendItems([.addMemoPlaceholder], toSection: .all)
        } else {
            snapshot.appendItems(allMemos.map({ .memo(MemoHomeUIModel(memo: $0, section: .all)) }), toSection: .all)
        }

        diffableDataSource.apply(snapshot)
    }
    
    private func setupDelegates() {
        self.homeCollectionView.delegate = self
    }
    
    private func bind() {
//        coreDataChangePublisher.sink { [weak self] _ in
//            guard let self else { return }
//            Task {
//                try await self.fetchData()
//                self.applySnapshot()
//            }
//        }
//        .store(in: &cancellables)
        
        ThemeManager.shared.currentThemePublisher
            .sink { [weak self] color in
                guard let self else { return }
                self.tabBarController?.tabBar.tintColor = UIColor.currentTheme
                self.navigationController?.navigationBar.tintColor = UIColor.currentTheme
                self.navigationController?.toolbar.tintColor = UIColor.currentTheme
                self.view.setNeedsLayout()
                self.homeCollectionView.visibleCells.forEach { cell in
                    // 테마 색에 맞게 그림자를 그리는 작업이 layoutSubviews에서 진행되기 때문...
                    cell.setNeedsLayout()
                }
            }.store(in: &cancellables)
        
        let coreDataChangeStream = coreDataChangePublisher.map { _ in return () }
        let orderSettingChangeStream = OrderSettingManager.shared.orderSettingChangedPublisher
        
        coreDataChangeStream
            .merge(with: orderSettingChangeStream)
            .sink { [weak self] _ in
                guard let self else { return }
                Task {
                    try await self.fetchData()
                    self.applySnapshot()
                }
            }
            .store(in: &cancellables)
    }
    
    @objc private func onHeaderButtonTapped(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            let categoryListVC = CategoryListViewController()
            self.navigationController?.pushViewController(categoryListVC, animated: true)
        case 1:
            let favoriteMemoVC = MemoViewController(memoVCType: .favorite)
            favoriteMemoVC.navigationItem.leftBarButtonItem = nil
            self.navigationController?.pushViewController(favoriteMemoVC, animated: true)
        case 2:
            let allMemoVC = MemoViewController(memoVCType: .all)
            self.navigationController?.pushViewController(allMemoVC, animated: true)
        default:
            fatalError()
        }
    }
    
    @objc private func memoCreated() {
        self.homeCollectionView.reloadData()
    }
    
    @objc private func memoEdited() {
        self.homeCollectionView.reloadData()
    }
    
}

// MARK: - UICollectionViewDelegate

extension HomeViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        // 빈 상태 placeholder 탭: 카테고리/메모 생성 화면을 곧바로 띄운다.
        if let itemIdentifier = diffableDataSource.itemIdentifier(for: indexPath) {
            switch itemIdentifier {
            case .addCategoryPlaceholder:
                let createCategoryVC = CreateCategoryViewController()
                let naviCon = UINavigationController(rootViewController: createCategoryVC)
                present(naviCon, animated: true)
                return
            case .addMemoPlaceholder:
                let memoMakingVC = MemoDetailViewController(type: .making(category: nil))
                let naviCon = UINavigationController(rootViewController: memoMakingVC)
                present(naviCon, animated: true)
                return
            case .category, .memo:
                break
            }
        }

        let config = WispConfiguration { config in
            config.setLayout { layout in
                let topInset: CGFloat
                if #available(iOS 26.0, *), [.pad, .vision].contains(UIDevice.current.userInterfaceIdiom) {
                    topInset = view.safeAreaInsets.top
                } else {
                    topInset = tabBarController?.view.safeAreaInsets.top ?? view.safeAreaInsets.top
                }
                layout.presentedAreaInset = .init(top: topInset, left: 0, bottom: 0, right: 0)
                layout.initialCornerRadius = 20
                layout.finalCornerRadius = 37
            }
            config.setGesture { gesture in
                gesture.allowedDirections = [.horizontal, .down]
            }
        }
        
        switch indexPath.section {
        case 0:
            switch CategoryEntityManager.shared.getCategoryEntities(inOrderOf: .modificationDate, isAscending: false).count != 0 {
            case false:
                let createCategoryVC = CreateCategoryViewController()
                let naviCon = UINavigationController(rootViewController: createCategoryVC)
                present(naviCon, animated: true)
            case true:
                let selectedCategory = categories[indexPath.item]
                let memoVC = MemoViewController(memoVCType: .category(selectedCategory: selectedCategory))
                self.navigationController?.pushViewController(memoVC, animated: true)
            }
            
        case 1:
            switch MemoEntityManager.shared.getFavoriteMemoEntities().count {
            case 0:
                return
                
            default:
                let selectedMemo = favoriteMemos[indexPath.item]
                let popupCardViewCotroller = PopupCardViewController(
                    memo: selectedMemo,
                    indexPath: indexPath,
                )
                wisp.present(popupCardViewCotroller, collectionView: homeCollectionView, at: indexPath, configuration: config)
            }
        case 2:
            let selectedMemo = allMemos[indexPath.item]
            let popupCardViewCotroller = PopupCardViewController(
                memo: selectedMemo,
                indexPath: indexPath,
            )
            wisp.present(popupCardViewCotroller, collectionView: homeCollectionView, at: indexPath, configuration: config)
        default:
            fatalError("HomeCollectionView's number of sections is 3")
        }
    }
    
}
