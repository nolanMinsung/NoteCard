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
    
    let homeView = HomeView()
    
    lazy var homeCollectionView = self.homeView.homeCollectionView
    
    var favoriteMemoArray: [MemoEntity] {
        return MemoEntityManager.shared.getFavoriteMemoEntities()
    }
    var recentMemoArray: [MemoEntity] {
        return MemoEntityManager.shared.getMemoEntitiesFromCoreData()
    }
    
    override func loadView() {
        self.view = homeView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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
    
    private func setupUI() { }
    
    private func setupNaviBar() {
        self.title = "홈 화면".localized()
        
        let appearanceForStandard: UINavigationBarAppearance = {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            //appearance.titleTextAttributes = [.foregroundColor: UIColor.currentTheme()]
            //appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.currentTheme()]
            return appearance
        }()
        
        let appearanceForScrollEdge: UINavigationBarAppearance = {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            //appearance.titleTextAttributes = [.foregroundColor: UIColor.currentTheme()]
            //appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.currentTheme()]
            return appearance
        }()
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearanceForScrollEdge
        self.navigationController?.navigationBar.standardAppearance = appearanceForStandard
        
        self.navigationController?.navigationBar.tintColor = .currentTheme()
        self.navigationController?.toolbar.tintColor = .currentTheme()
    }
    
    
    private func setupDelegates() {
        self.homeCollectionView.dataSource = self
        self.homeCollectionView.delegate = self
    }
    
    
    private func setupObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(memoCreated),
                                               name: NSNotification.Name("createdMemoNotification"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(themeColorChanged),
                                               name: NSNotification.Name("themeColorChangedNotification"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("didCreateNewCategoryNotification"),
            object: nil, queue: nil
        ) { [weak self] _ in
            guard let self else { fatalError() }
            guard let homeView = self.view as? HomeView else { return }
            homeView.homeCollectionView.reloadData()
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(memoEdited),
                                               name: NSNotification.Name("editingCompleteNotification"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("headerTapped"),
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let self else { fatalError() }
            guard let headerView = notification.object as? HomeHeaderView else { return }
            guard let naviCon = self.tabBarController?.selectedViewController as? UINavigationController else { return }
            
            switch headerView.section {
            case 0:
                let categoryListVC = CategoryListViewController()
                naviCon.pushViewController(categoryListVC, animated: true)
            case 1:
                let favoriteMemoVC = MemoViewController(memoVCType: .favorite)
                favoriteMemoVC.navigationItem.leftBarButtonItem = nil
                naviCon.pushViewController(favoriteMemoVC, animated: true)
            case 2:
                let allMemoVC = MemoViewController(memoVCType: .all)
                naviCon.pushViewController(allMemoVC, animated: true)
            default:
                fatalError()
            }
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
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let headerView = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: HomeHeaderView.reuseIdentifier,
            for: indexPath
        ) as! HomeHeaderView
        
        headerView.section = indexPath.section
        headerView.button.configuration?.title = sectionHederTitleArray[indexPath.section] + " "
        
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
                guard let selectedCell = collectionView.cellForItem(at: indexPath) as? HomeCardCell else { return }
                guard let selectedMemoEntity = selectedCell.memoEntity else { return }
                
                let convertedRect = selectedCell.convert(selectedCell.contentView.frame, to: self.view)
                let popupCardVC = PopupCardViewController(memo: selectedMemoEntity, selectedCollectionViewCell: selectedCell, indexPath: indexPath, selectedCellFrame: convertedRect, cornerRadius: 20, isInteractive: true)
                popupCardVC.modalPresentationStyle = UIModalPresentationStyle.custom
                popupCardVC.transitioningDelegate = self
                
                self.tabBarController?.present(popupCardVC, animated: true)
            }
            
        case 2:
            guard let selectedCell = collectionView.cellForItem(at: indexPath) as? HomeCardCell else { return }
            guard let selectedMemoEntity = selectedCell.memoEntity else { return }
            
            let convertedRect = selectedCell.convert(selectedCell.contentView.frame, to: self.view)
            let popupCardVC = PopupCardViewController(memo: selectedMemoEntity, selectedCollectionViewCell: selectedCell, indexPath: indexPath, selectedCellFrame: convertedRect, cornerRadius: 20, isInteractive: true)
            popupCardVC.modalPresentationStyle = UIModalPresentationStyle.custom
            popupCardVC.transitioningDelegate = self
            
            self.tabBarController?.present(popupCardVC, animated: true)
            
        default:
            fatalError("HomeCollectionView's number of sections is 3")
        }
    }
    
}

extension HomeViewController: UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        if source == self.tabBarController {
            return PopupCardPresentationController(presentedViewController: presented, presenting: presenting, blurBrightness: UIBlurEffect.Style.extraLight)
        } else {
            return nil
        }
    }
    
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return HomeViewPopupCardAnimatedTransitioning(animationType: AnimationType.present)
    }
    
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if let popupCardVC = dismissed as? PopupCardViewController {
            return HomeViewPopupCardAnimatedTransitioning(animationType: AnimationType.dismiss, interactiveTransition: popupCardVC.percentDrivenInteractiveTransition)
        } else {
            return nil
        }
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        
        guard let homeViewPopupCardAnimatedTransitioning = animator as? HomeViewPopupCardAnimatedTransitioning,
              let percentDrivenInteractiveTransition = homeViewPopupCardAnimatedTransitioning.interactiveTransition,
              percentDrivenInteractiveTransition.interactionInProgress
        else { return nil }
        return percentDrivenInteractiveTransition
    }
    
}


