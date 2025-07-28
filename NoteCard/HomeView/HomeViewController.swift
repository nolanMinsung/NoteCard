//
//  HomeViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class HomeViewController: UIViewController {
    
    let sectionHederTitleArray: [String] = [
        "카테고리".localized(),
        "즐겨찾기".localized(),
        "전체 메모".localized()
    ]
    
    lazy var homeView = HomeView()
    
    var homeCollectionView: WispableCollectionView { self.homeView.homeCollectionView }
    
    private var favoriteMemoArray: [MemoEntity] {
        return MemoEntityManager.shared.getFavoriteMemoEntities()
    }
    private var recentMemoArray: [MemoEntity] {
        return MemoEntityManager.shared.getMemoEntitiesFromCoreData()
    }
    
    override func loadView() {
        self.view = homeView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNaviBar()
        setupDelegates()
        setupObserver()
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
        
        self.navigationController?.navigationBar.tintColor = .currentTheme()
        self.navigationController?.toolbar.tintColor = .currentTheme()
    }
    
    private func setupDelegates() {
        self.homeCollectionView.dataSource = self
        self.homeCollectionView.delegate = self
    }
    
    private func setupObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(memoCreated),
            name: NSNotification.Name("createdMemoNotification"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeColorChanged),
            name: NSNotification.Name("themeColorChangedNotification"),
            object: nil
        )
        
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
    
    @objc private func themeColorChanged() {
        self.tabBarController?.tabBar.tintColor = UIColor.currentTheme()
        self.navigationController?.navigationBar.tintColor = UIColor.currentTheme()
        self.navigationController?.toolbar.tintColor = UIColor.currentTheme()
        self.homeCollectionView.reloadData()
    }
    
    @objc private func memoEdited() {
        self.homeCollectionView.reloadData()
    }
    
}

// MARK: - UICollectionViewDataSource

extension HomeViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.sectionHederTitleArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            switch CategoryEntityManager.shared.getCategoryEntities(inOrderOf: CategoryProperties.modificationDate, isAscending: false).count != 0 {
            case false:
                return 1
            case true:
                return CategoryEntityManager.shared.getCategoryEntities(inOrderOf: CategoryProperties.modificationDate, isAscending: false).count
            }
            
        case 1:
            switch MemoEntityManager.shared.getFavoriteMemoEntities().count {
            case 0:
                return 1
            default:
                return MemoEntityManager.shared.getFavoriteMemoEntities().count
            }
            
        default:
            return MemoEntityManager.shared.getMemoEntitiesFromCoreData().count
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        
        guard let headerView = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: HomeHeaderView.reuseIdentifier,
            for: indexPath
        ) as? HomeHeaderView else {
            fatalError()
        }
        
        headerView.button.configuration?.baseForegroundColor = UIColor.currentTheme()
        // 헤더 안의 버튼은 section 정보를 button의 tag로 저장함.
        headerView.button.tag = indexPath.section
        headerView.button.configuration?.title = sectionHederTitleArray[indexPath.section] + " "
        headerView.button.addTarget(self, action: #selector(onHeaderButtonTapped), for: .touchUpInside)
        
        return headerView
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let categoryCell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeCategoryCell.reuseIdentifier, for: indexPath) as! HomeCategoryCell
            
            let categoryEntityArray = CategoryEntityManager.shared.getCategoryEntities(inOrderOf: CategoryProperties.modificationDate, isAscending: false)
            
            switch categoryEntityArray.count != 0 {
            case false:
                categoryCell.labelCategoryName.textColor = UIColor.systemGray
                categoryCell.labelCategoryName.text = "카테고리 만들기".localized()
                return categoryCell
                
            case true:
                categoryCell.labelCategoryName.textColor = .label
                categoryCell.labelCategoryName.text = categoryEntityArray[indexPath.row].name
                return categoryCell
            }
            
        case 1:
            let favoriteCell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeCardCell.reuseIdentifier, for: indexPath) as! HomeCardCell
            
            switch MemoEntityManager.shared.getFavoriteMemoEntities().count {
            case 0:
                favoriteCell.titleTextField.text = "즐겨찾기 없음".localized()
                favoriteCell.pictureImageLabel.isHidden = true
                favoriteCell.imageCountLabel.text = ""
                favoriteCell.dateLabel.text = ""
                favoriteCell.titleTextField.textColor = UIColor.lightGray
                return favoriteCell
                
            default:
                let memoEntity = favoriteMemoArray[indexPath.row]
                favoriteCell.configureCell(with: memoEntity)
                return favoriteCell
            }
            
        case 2:
            let recentCell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeCardCell.reuseIdentifier, for: indexPath) as! HomeCardCell
            
            let memoEntity = recentMemoArray[indexPath.row]
            recentCell.configureCell(with: memoEntity)
            return recentCell
            
        default:
            fatalError("HomeCollectionView's number of sections is 3")
        }
    }
}

// MARK: - UICollectionViewDelegate

extension HomeViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        switch indexPath.section {
        case 0:
            switch CategoryEntityManager.shared.getCategoryEntities(inOrderOf: .modificationDate, isAscending: false).count != 0 {
            case false:
                let createCategoryVC = CreateCategoryViewController()
                let naviCon = UINavigationController(rootViewController: createCategoryVC)
                present(naviCon, animated: true)
            case true:
                let selectedCategoryEntity = CategoryEntityManager.shared.getCategoryEntities(inOrderOf: CategoryProperties.modificationDate, isAscending: false)[indexPath.row]
                let memoVC = MemoViewController(memoVCType: .category, selectedCategoryEntity: selectedCategoryEntity)
                self.navigationController?.pushViewController(memoVC, animated: true)
            }
            
        case 1:
            switch MemoEntityManager.shared.getFavoriteMemoEntities().count {
            case 0:
                return
                
            default:
//                let cardViewController = WispCardViewController(
//                    cardInset: .init(top: 130, leading: 10, bottom: -130, trailing: -10)
//                )
                let cardViewController = WispViewController(
                    viewInset: .init(top: 130, leading: 10, bottom: 130, trailing: 10)
                )
                homeView.homeCollectionView.wisp.present(cardViewController, from: indexPath, in: self)
            }
        case 2:
            let topInset = tabBarController?.view.safeAreaInsets.top ?? view.safeAreaInsets.top
//            let cardViewController = WispCardViewController(
//                cardInset: .init(top: topInset, leading: 0, bottom: 0, trailing: 0),
//            )
            let cardViewController = WispViewController(
                viewInset: .init(top: topInset, leading: 0, bottom: 0, trailing: 0)
            )
            
            let naviCon = SampleOrangeNavigationController(
                viewInset: .init(top: topInset, leading: 0, bottom: 0, trailing: 0)
            )
            
            homeView.homeCollectionView.wisp.present(naviCon, from: indexPath, in: self)
        default:
            fatalError("HomeCollectionView's number of sections is 3")
        }
    }
    
}
