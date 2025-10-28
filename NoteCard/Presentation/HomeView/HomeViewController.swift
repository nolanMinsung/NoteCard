//
//  HomeViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import Combine
import UIKit

import Wisp

class HomeViewController: UIViewController {
    
    enum Section: CaseIterable {
        case category
        case favorite
        case all
    }
    
    enum HomeItem: Hashable {
        case category(Category)
        case memo(MemoHomeUIModel)
    }
    
    typealias DiffableDataSource = UICollectionViewDiffableDataSource<Section, HomeItem>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, HomeItem>
    typealias CellProvider = DiffableDataSource.CellProvider
    typealias HeaderRegistration = UICollectionView.SupplementaryRegistration<HomeHeaderView>
    typealias CategoryCellRegistration = UICollectionView.CellRegistration<HomeCategoryCell, Category>
    typealias MemoCellRegistration = UICollectionView.CellRegistration<HomeCardCell, MemoHomeUIModel>
    
    let sectionHederTitleArray: [String] = [
        "카테고리".localized(),
        "즐겨찾기".localized(),
        "전체 메모".localized()
    ]
    
    lazy var homeView = HomeView()
    
    var homeCollectionView: WispableCollectionView { self.homeView.homeCollectionView }
    
    private var categories: [Category] = []
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
        setupObserver()
        
        coreDataChangePublisher.sink { [weak self] _ in
            guard let self else { return }
            Task {
                try await self.fetchData()
                self.applySnapshot()
            }
        }
        .store(in: &cancellables)
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
        self.title = "홈 화면".localized()
        
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
        categories = try await CategoryEntityRepository.shared.getAllCategories(
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
        snapshot.appendItems(categories.map({ .category($0) }), toSection: .category)
        snapshot.appendItems(favoriteMemos.map({ .memo(MemoHomeUIModel(memo: $0, section: .favorite)) }), toSection: .favorite)
        snapshot.appendItems(allMemos.map({ .memo(MemoHomeUIModel(memo: $0, section: .all)) }), toSection: .all)
        diffableDataSource.apply(snapshot)
    }
    
    private func setupDelegates() {
        self.homeCollectionView.delegate = self
    }
    
    private func setupObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(memoCreated),
            name: NSNotification.Name("createdMemoNotification"),
            object: nil
        )
        
        Task {
            await ThemeManager.shared.currentThemePublisher.sink { [weak self] color in
                guard let self else { return }
                Task {
                    self.tabBarController?.tabBar.tintColor = UIColor.currentTheme
                    self.navigationController?.navigationBar.tintColor = UIColor.currentTheme
                    self.navigationController?.toolbar.tintColor = UIColor.currentTheme
                    self.homeCollectionView.reloadData()
                }
            }.store(in: &cancellables)
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("didCreateNewCategoryNotification"),
            object: nil, queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            guard let homeView = self.view as? HomeView else { return }
            homeView.homeCollectionView.reloadData()
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(memoEdited),
            name: NSNotification.Name("editingCompleteNotification"),
            object: nil
        )
        
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
        
        let config = WispConfiguration { config in
            config.setLayout { layout in
                let topInset = tabBarController?.view.safeAreaInsets.top ?? view.safeAreaInsets.top
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
