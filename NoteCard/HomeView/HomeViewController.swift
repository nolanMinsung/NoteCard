//
//  HomeViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class HomeViewController: UIViewController {
    
    private let cardRestoringSizeAnimator = UIViewPropertyAnimator(
        duration: 0.7,
        dampingRatio: 1
    )
    
    private let cardRestoringMovingAnimator = UIViewPropertyAnimator(
        duration: 0.6,
        dampingRatio: 0.8
    )
    
    // 현재 선택된 셀의 IndexPath
    var restoringIndexPath: IndexPath? {
        didSet {
            guard let restoringIndexPath else { return }
            guard let cell = self.homeCollectionView.cellForItem(at: restoringIndexPath) else { return }
            let convertedFrame = cell.convert(cell.contentView.frame, to: self.view)
            print("convertedFrame: \(convertedFrame)")
            homeView.restoringCard.frame = convertedFrame
            view.layoutIfNeeded()
        }
    }
    
    /// 이 속성이 `present`될 (Card)뷰컨트롤러의 `transitioningDelegate`가 됨.
    /// 원래 뷰컨트롤러는 본인의 `transitioningDelegate` 를 약하게 참조.
    /// 따라서 dismiss하기 전에
    var cardTransitioningDelegate: CardTransitioningDelegate? = nil
    
    let sectionHederTitleArray: [String] = [
        "카테고리".localized(),
        "즐겨찾기".localized(),
        "전체 메모".localized()
    ]
    
    lazy var favoriteSectionHandler: NSCollectionLayoutSectionVisibleItemsInvalidationHandler
    = { [weak self] visibleItems, offset, env in
        guard let self else { return }
        print("offset: \(offset)")
        guard let restoringIndexPath, restoringIndexPath.section == 1 else { return }
        guard let cell = self.homeCollectionView.cellForItem(at: restoringIndexPath) else { return }
        let convertedFrame = cell.convert(cell.contentView.frame, to: self.view)
        print("convertedFrame: \(convertedFrame)")
        homeView.restoringCard.frame = convertedFrame
        view.layoutIfNeeded()
    }
    
    lazy var allSectionHandler: NSCollectionLayoutSectionVisibleItemsInvalidationHandler
    = { [weak self] visibleItems, offset, env in
        guard let self else { return }
        print("offset: \(offset)")
        guard let restoringIndexPath, restoringIndexPath.section == 2 else { return }
        guard let cell = self.homeCollectionView.cellForItem(at: restoringIndexPath) else { return }
        let convertedFrame = cell.convert(cell.contentView.frame, to: self.view)
        print("convertedFrame: \(convertedFrame)")
        homeView.restoringCard.frame = convertedFrame
        view.layoutIfNeeded()
    }
    
    lazy var homeView = HomeView(
        favoriteSectionHandler: favoriteSectionHandler,
        allSectionHandler: allSectionHandler
    )
    
    var homeCollectionView: HomeCollectionView { self.homeView.homeCollectionView }
    
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
            // 앱을 새로 구성할 때, 숨김 표시 여부 확인
            categoryCell.isHidden = (restoringIndexPath == indexPath)
            
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
            
            favoriteCell.isHidden = (restoringIndexPath == indexPath)
            
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
            
            recentCell.isHidden = (restoringIndexPath == indexPath)
            
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
                guard let selectedCell = collectionView.cellForItem(at: indexPath) as? HomeCardCell else { return }
                guard let selectedMemoEntity = selectedCell.memoEntity else { return }
                
                makeSelectedCellInvisible(indexPath: indexPath)
                
                let convertedCellFrame = selectedCell.convert(selectedCell.contentView.frame, to: self.view)
                
                let cardViewController = CardViewController(memoEntity: selectedMemoEntity)
                cardTransitioningDelegate = CardTransitioningDelegate(
                    presenting: self,
                    collectionView: homeCollectionView,
                    selectedIndexPath: indexPath,
                    startFrame: convertedCellFrame,
                    cellSnapshot: selectedCell.snapshotView(afterScreenUpdates: false)
                )
                cardViewController.transitioningDelegate = cardTransitioningDelegate
                cardViewController.modalPresentationStyle = .custom
                
                // 실제로는 tab bar controller 가 present
                present(cardViewController, animated: true)
            }
            
        case 2:
            guard let selectedCell = collectionView.cellForItem(at: indexPath) as? HomeCardCell else { return }
            guard let selectedMemoEntity = selectedCell.memoEntity else { return }
            
            makeSelectedCellInvisible(indexPath: indexPath)
            
            let convertedCellFrame = selectedCell.convert(selectedCell.contentView.frame, to: self.view)
            
            let cardViewController = CardViewController(memoEntity: selectedMemoEntity)
            cardTransitioningDelegate = CardTransitioningDelegate(
                presenting: self,
                collectionView: homeCollectionView,
                selectedIndexPath: indexPath,
                startFrame: convertedCellFrame,
                cellSnapshot: selectedCell.snapshotView(afterScreenUpdates: false)
            )
            cardViewController.transitioningDelegate = cardTransitioningDelegate
            cardViewController.modalPresentationStyle = .custom
            self.present(cardViewController, animated: true)
            
        default:
            fatalError("HomeCollectionView's number of sections is 3")
        }
    }
    
}

// MARK: - UIViewControllerTransitioningDelegate

//extension HomeViewController: UIViewControllerTransitioningDelegate {
//    
//    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
//        
//        if source == self.tabBarController {
//            return PopupCardPresentationController(presentedViewController: presented, presenting: presenting, blurBrightness: UIBlurEffect.Style.extraLight)
//        } else {
//            return nil
//        }
//    }
//    
//    
//    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        return HomeViewPopupCardAnimatedTransitioning(animationType: AnimationType.present)
//    }
//    
//    
//    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        
//        if let popupCardVC = dismissed as? PopupCardViewController {
//            return HomeViewPopupCardAnimatedTransitioning(animationType: AnimationType.dismiss, interactiveTransition: popupCardVC.percentDrivenInteractiveTransition)
//        } else {
//            return nil
//        }
//    }
//    
//    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
//        
//        guard let homeViewPopupCardAnimatedTransitioning = animator as? HomeViewPopupCardAnimatedTransitioning,
//              let percentDrivenInteractiveTransition = homeViewPopupCardAnimatedTransitioning.interactiveTransition,
//              percentDrivenInteractiveTransition.interactionInProgress
//        else { return nil }
//        return percentDrivenInteractiveTransition
//    }
//    
//}


// MARK: - CardFrameRestorable
extension HomeViewController: CardFrameRestorable {
    
    func getFrameOfSelectedCell(indexPath: IndexPath) -> CGRect? {
        guard let selectedCell = homeCollectionView.cellForItem(at: indexPath) else { return nil }
        return selectedCell.convert(selectedCell.contentView.frame, to: view)
    }
    
    func makeSelectedCellInvisible(indexPath: IndexPath) {
        guard let selectedCell = homeCollectionView.cellForItem(at: indexPath) as? HomeCardCell else { return }
        selectedCell.alpha = 0
    }
    
    func makeSelectedCellVisible(indexPath: IndexPath) {
        guard let selectedCell = homeCollectionView.cellForItem(at: indexPath) as? HomeCardCell else { return }
        selectedCell.alpha = 1
    }
    
    func getTranslationT(startFrame: CGRect, endFrame: CGRect) -> CGAffineTransform {
        return .init(
            translationX: startFrame.center.x - endFrame.center.x,
            y: startFrame.center.y - endFrame.center.y
        )
    }
    
    func getDistanceDiff(startFrame: CGRect, endFrame: CGRect) -> CGPoint {
        return .init(
            x: startFrame.center.x - endFrame.center.x,
            y: startFrame.center.y - endFrame.center.y
        )
    }
    
    func getScaleT(startFrame: CGRect, endFrame: CGRect) -> CGAffineTransform {
        return.init(
            scaleX: startFrame.width / endFrame.width,
            y: startFrame.height / endFrame.height
        )
    }
    
    func restore(startFrame: CGRect, indexPath: IndexPath) {
        guard let cardTransitioningDelegate else { return }
        guard let restoringIndexPath = cardTransitioningDelegate.restoringIndexPath else { return }
        self.restoringIndexPath = restoringIndexPath
        guard let targetCell = homeCollectionView.cellForItem(
            at: restoringIndexPath
        ) as? HomeCardCell else { fatalError() }
        
        // restoring card 초기 위치, 크기 설정
        let convertedCellFrame = targetCell.convert(targetCell.contentView.frame, to: self.view)
        let scaleT = getScaleT(startFrame: startFrame, endFrame: convertedCellFrame)
        let distanceDiff = getDistanceDiff(startFrame: startFrame, endFrame: convertedCellFrame)
        homeView.restoringCard.center.x += distanceDiff.x
        homeView.restoringCard.center.y += distanceDiff.y
        homeView.restoringCard.transform = scaleT
        
        // restoring card 초기 디자인 설정
        homeView.restoringCard.blurView.effect = UIBlurEffect(style: .regular)
        homeView.restoringCard.isHidden = false
        homeView.restoringCard.alpha = 1
        homeView.restoringCard.layer.cornerRadius = 20
        homeView.restoringCard.clipsToBounds = true
        
        // restoring card snapshot 설정
        homeView.restoringCard.setupSnapshots(
            viewSnapshot: cardTransitioningDelegate.viewSnapshot,
            cellSnapshot: cardTransitioningDelegate.cellSnapshot
        )
        
        cardRestoringMovingAnimator.addAnimations { [weak self] in
            self?.homeView.restoringCard.center.x -= distanceDiff.x
            self?.homeView.restoringCard.center.y -= distanceDiff.y
            self?.view.layoutIfNeeded()
        }
        
        cardRestoringSizeAnimator.addAnimations { [weak self] in
            self?.homeView.restoringCard.switchSnapshots()
            self?.homeView.restoringCard.transform = .identity
            self?.view.layoutIfNeeded()
        }
        
        cardRestoringSizeAnimator.addCompletion { [weak self] stoppedPosition in
            self?.homeView.restoringCard.setStateAfterRestore()
            self?.makeSelectedCellVisible(indexPath: indexPath)
            self?.restoringIndexPath = nil
        }
        
        cardRestoringMovingAnimator.startAnimation()
        cardRestoringSizeAnimator.startAnimation()
    }
    
}


