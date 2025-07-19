//
//  TotalListViewPopupCardAnimatedTransitioning.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/26.
//


import UIKit
/*
enum AnimationType {
    case present
    case dismiss
}
*/

final class TotalListViewPopupCardAnimatedTransitioning: NSObject {
    
    var userDefaultCriterion: String? { UserDefaults.standard.string(forKey: UserDefaultsKeys.orderCriterion.rawValue) }
    
    let screenSize = UIScreen.current?.bounds.size
    let presentationPropertyAnimator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1)
    
//    let presentationPropertyAnimatorForBars: UIViewPropertyAnimator = {
//        let animator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1)
//        animator.isInterruptible = true
//        return animator
//    }()
    
    let dismissalPropertyAnimator: UIViewPropertyAnimator = {
        let animator = UIViewPropertyAnimator(duration: 0.35, dampingRatio: 0.83)
        return animator
    }()
    
    let disappearingPropertyAnimator: UIViewPropertyAnimator = {
        let animator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 0.83)
        return animator
    }()
    
    let dismissalPropertyAnimatorForBars: UIViewPropertyAnimator = {
        let animator = UIViewPropertyAnimator(duration: 0.7, dampingRatio: 1)
        return animator
    }()
    
    var animationType: AnimationType
    let interactiveTransition: PercentDrivenInteractiveTransition?
    
    //interactiveTransition의 기본값으로 nil을 넣은 것은 HomeViewController에서 UIViewControllerAnimatedTransitioning 타입을 반환하는 함수에서
    //presentation 용으로 반환할 수도 있기 때문임
    init(animationType: AnimationType, interactiveTransition: PercentDrivenInteractiveTransition? = nil) {
        self.animationType = animationType
        self.interactiveTransition = interactiveTransition
        super.init()
    }
}


extension TotalListViewPopupCardAnimatedTransitioning: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 2
    }
    
    /*
    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? PopupCardViewController else { return UIViewPropertyAnimator() }
        guard let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? UITabBarController else { return UIViewPropertyAnimator() }
        guard let selectedNaviCon = toVC.selectedViewController as? UINavigationController else { return UIViewPropertyAnimator() }
        
        let selectedCellFrame = fromVC.selectedCellFrame
        
        
        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.7)
        animator.addAnimations {
            toVC.view.alpha = 1.0
            fromVC.view.frame = selectedCellFrame
            let popupCardView = fromVC.view as! PopupCardView
            popupCardView.memoTitleLabelTopConstraint.constant = 6
            popupCardView.memoTitleLabelLeadingConstraint.constant = 15
            popupCardView.selectedImageCollectionViewHeightConstraint.constant = 0
            popupCardView.memoTextViewLeadingConstraint.constant = 15
            popupCardView.memoTextViewTrailingConstraint.constant = -15
            popupCardView.memoTextView.bounds.origin = CGPoint(x: 0, y: 0)
            fromVC.view.layer.cornerRadius = 20
            popupCardView.layoutIfNeeded()
//            popupCardView.selectedImageCollectionView.frame.size = CGSize(width: 0, height: 0)
            
        }
        
        //내비게이션바와 탭바를 화면 바깥으로 밀어내는 코드
        animator.addAnimations({
            fromVC.view.alpha = 1
            selectedNaviCon.navigationBar.bounds.origin.y = 0
            toVC.tabBar.frame.origin.y = 844 - toVC.tabBar.frame.height
            
        }, delayFactor: 0.5)
        
        
        animator.addCompletion { (position) in
            //애니메이션이 취소되지 않고 완료했음을 알리는 코드
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        return animator
    }
    */
    
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        switch self.animationType {
        case .present:
            self.animationForPresentation(using: transitionContext)
        case .dismiss:
            self.animationForDismissal(using: transitionContext)
            
        }
        
    }
    
    
    private func animationForPresentation(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let screenSize else { return }
        
        guard let popupCardVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? PopupCardViewController else { return }
        
        let selectedCell = popupCardVC.selectedCollectionViewCell
        let selectedCellFrame = popupCardVC.selectedCellFrame
        let cornerRadius = popupCardVC.cornerRadius
        let containerView = transitionContext.containerView
        containerView.addSubview(popupCardVC.view)
        
        selectedCell.alpha = 0
        
        let popupCardView = popupCardVC.view as! PopupCardView
        popupCardView.frame = selectedCellFrame
        popupCardView.layer.cornerRadius = cornerRadius
        popupCardView.titleTextFieldTopConstraint.constant = 10
        popupCardView.titleTextFieldLeadingConstraint.constant = 15
        popupCardView.ellipsisButton.alpha = 0
        popupCardView.heartImageViewTopConstraint.constant = 10
        popupCardView.heartImageViewTrailingConstraint.isActive = false
        popupCardView.heartImageViewTrailingToPopupCardViewConstraint.isActive = true
        popupCardView.heartImageViewWidthConstraint.constant = 30
        popupCardView.heartImageViewHeightConstraint.constant = 30
        popupCardView.selectedImageCollectionViewTopConstraint.constant = 0
        popupCardView.selectedImageCollectionViewHeightConstraint.constant = 0
        popupCardView.memoTextViewLeadingConstraint.constant = 10
        popupCardView.memoTextViewTrailingConstraint.constant = -10
        popupCardView.memoTextView.bounds.origin.x = 0
        popupCardView.layoutIfNeeded()
        
        guard let fromVC = transitionContext.viewController(forKey: .from) as? UITabBarController else { fatalError() }
        guard let naviCon = fromVC.selectedViewController as? UINavigationController else { fatalError() }
        guard let totalListVC = naviCon.topViewController as? TotalListViewController else { fatalError() }
//        guard let searchBarHeight = totalListVC.navigationItem.searchController?.searchBar.bounds.height else { fatalError() }
        
        self.presentationPropertyAnimator.addAnimations {
            fromVC.tabBar.frame.origin.y = screenSize.height
            naviCon.navigationBar.bounds.origin.y = naviCon.navigationBar.bounds.height + naviCon.view.safeAreaInsets.top
//            naviCon.extendedNaviBarTopConstraint.constant = -(naviCon.navigationBar.bounds.height + searchBarHeight + naviCon.view.safeAreaInsets.top)
//            print(naviCon.extendedNaviBar.bounds.height + naviCon.view.safeAreaInsets.top, "extendedbar's height + top safeAreaInset")
//            print(naviCon.extendedNaviBar.bounds.height)
            print(naviCon.view.safeAreaInsets.top)
            naviCon.view.layoutIfNeeded()
        }
        
        self.presentationPropertyAnimator.addAnimations {
            guard let screenRect = popupCardView.window?.windowScene?.screen.bounds else { fatalError() }
            let screenWidth = screenRect.width
            let screenHeight = screenRect.height
//            popupCardView.frame = CGRect(x: 20, y: 160, width: 350, height: 550)
            let horizontalInset: CGFloat = screenWidth / 40
            let verticalInset: CGFloat = screenHeight * 0.145
            popupCardView.frame = CGRect(x: horizontalInset, y: verticalInset, width: screenWidth - (horizontalInset * 2), height: screenHeight - (verticalInset * 2))
            
            popupCardView.layer.cornerRadius = 37
            popupCardView.layer.cornerCurve = .continuous
            
            popupCardView.titleTextFieldTopConstraint.constant = 10
            popupCardView.titleTextFieldLeadingConstraint.constant = 20
            
            popupCardView.heartImageViewTopConstraint.constant = 14
            popupCardView.heartImageViewLeadingConstraint.constant = 10
            popupCardView.heartImageViewTrailingToPopupCardViewConstraint.isActive = false
            popupCardView.heartImageViewTrailingConstraint.isActive = true
            popupCardView.heartImageViewWidthConstraint.constant = 27
            popupCardView.heartImageViewHeightConstraint.constant = 27
            popupCardView.selectedImageCollectionViewTopConstraint.constant = 6
            popupCardView.selectedImageCollectionViewHeightConstraint.constant = popupCardView.numberOfImages == 0 ? 0 : 70
            
//            
//            switch popupCardView.numberOfImages {
//            case 0:
//                popupCardView.selectedImageCollectionViewHeightConstraint.constant = 0
//            default:
//                popupCardView.selectedImageCollectionViewHeightConstraint.constant = 75
//            }
            
            popupCardView.memoTextViewLeadingConstraint.constant = 10
            popupCardView.memoTextViewTrailingConstraint.constant = -10
            popupCardView.memoTextView.bounds.origin.y = 0
            popupCardView.layoutIfNeeded()
        }
        
        self.presentationPropertyAnimator.addAnimations ({
            popupCardView.ellipsisButton.alpha = 1
        }, delayFactor: 0.1)
        
        self.presentationPropertyAnimator.addCompletion { animatingPosition in transitionContext.completeTransition(true) }
        
        self.presentationPropertyAnimator.startAnimation()
    }
    
    
    
    
    
    
    
    
    
//-------------------------------------------------------------------------------------------------------------------------------------
    
    
    
    
    
    
    
    
    
    private func animationForDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let screenSize else { return }
        
        guard let popupCardVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? PopupCardViewController else { return }
        
        
        var selectedCell: TotalListCollectionViewCell
        
        //MARK: -
//        var selectedCell: TotalListTableViewCell
        
        var convertedRect: CGRect = .zero
        let popupCardView = popupCardVC.view as! PopupCardView
        popupCardView.ellipsisButton.alpha = 0
        if popupCardVC.memoEntity.isFavorite {
            popupCardView.heartImageView.image = UIImage(systemName: "heart.fill")
        }
        
        //selectedCell을 앞으로 빼기 위해서 아래 if 문들을 guard 문으로 변경
        guard let tabBarCon = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? UITabBarController else { fatalError() }
        guard let naviCon = tabBarCon.selectedViewController as? UINavigationController else { fatalError() }
        guard let totalListVC = naviCon.topViewController as? TotalListViewController else { fatalError() }
        guard let searchCon = totalListVC.navigationItem.searchController else { fatalError() }
        
        
        self.disappearingPropertyAnimator.addAnimations {
            popupCardView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            popupCardView.alpha = 0
            popupCardView.layoutIfNeeded()
        }
        
        self.dismissalPropertyAnimatorForBars.addAnimations({
            naviCon.navigationBar.bounds.origin.y = 0
            tabBarCon.tabBar.frame.origin.y = screenSize.height - tabBarCon.tabBar.frame.height
//            naviCon.extendedNaviBar.bounds.origin.y = 0
//            naviCon.extendedNaviBarTopConstraint.constant = 0
            naviCon.view.layoutIfNeeded()
        }, delayFactor: 0.5)
        
        self.disappearingPropertyAnimator.addCompletion { position in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        if !totalListVC.memoEntitySearhResult.contains(popupCardVC.memoEntity) {
            disappearingPropertyAnimator.startAnimation()
            dismissalPropertyAnimatorForBars.startAnimation()
            return
        }
        
        
        //MARK: -
        selectedCell = totalListVC.totalListCollectionView.cellForItem(at: popupCardVC.selectedIndexPath) as! TotalListCollectionViewCell
        
//        if !popupCardVC.isMemoEdited {
//        if !popupCardView.isTextFieldChanged && !popupCardView.isTextViewChanged {
        
        /*
        if !popupCardView.isEdited {
            
            if popupCardVC.memoEntity.isInTrash {
                
//                totalListVC.applySnapshot(animatingDifferences: false, usingReloadData: true)
                
                self.dismissalPropertyAnimatorForBars.addAnimations {
                    naviCon.navigationBar.bounds.origin.y = 0
                    tabBarCon.tabBar.frame.origin.y = screenSize.height - tabBarCon.tabBar.frame.height
                }
                
                self.dismissalPropertyAnimator.addAnimations {
                    popupCardView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                    popupCardView.alpha = 0
                    popupCardView.layoutIfNeeded()
                }
                
                self.dismissalPropertyAnimator.addCompletion { position in
                    transitionContext.completeTransition(true)
                }
                
                dismissalPropertyAnimator.startAnimation()
                dismissalPropertyAnimatorForBars.startAnimation()
                
                return
                
            } else {
                
                selectedCell = totalListVC.totalListCollectionView.cellForItem(at: popupCardVC.selectedIndexPath) as! TotalListCollectionViewCell
                
                //MARK: -
//                selectedCell = totalListVC.totalListTableView.cellForRow(at: popupCardVC.selectedIndexPath) as! TotalListTableViewCell
            }
            
        //수정했을 때
        } else {
            
            //수정했는데 검색한 단어가 없을 때
            guard let searchText = searchCon.searchBar.text else { fatalError() }
            if !searchCon.isActive {
                
            //수정했는데 검색한 단어가 있을 때
            } else {
                
                let searchResult = MemoEntityManager.shared.searchMemoEntity(with: searchText, order: MemoProperties.modificationDate, ascending: false)
                
                //현재 카드가 검색 대상 목록에서 사라졌을 때(검색했던 검색어를 메모에서 지운 경우)
                if !searchResult.contains(popupCardVC.memoEntity) {
                    
                    self.dismissalPropertyAnimatorForBars.addAnimations {
                        naviCon.navigationBar.bounds.origin.y = 0
                        tabBarCon.tabBar.frame.origin.y = screenSize.height - tabBarCon.tabBar.frame.height
                    }
                    
                    self.dismissalPropertyAnimator.addAnimations {
                        popupCardView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                        popupCardView.alpha = 0
                        popupCardView.layoutIfNeeded()
                    }
                    
                    self.dismissalPropertyAnimator.addCompletion { position in
                        transitionContext.completeTransition(true)
                    }
                    
                    dismissalPropertyAnimator.startAnimation()
                    dismissalPropertyAnimatorForBars.startAnimation()
                    
                    return
                }
                
            }
            
            
            if userDefaultCriterion == OrderCriterion.modificationDate.rawValue {
                
                guard let isOrderAscending = UserDefaults.standard.value(forKey: KeysForUserDefaults.isOrderAscending.rawValue) as? Bool else { fatalError() }
                if isOrderAscending {
                    
                    
                    let numberOfItems = totalListVC.totalListCollectionView.numberOfItems(inSection: 0)
                    totalListVC.totalListCollectionView.scrollToItem(at: IndexPath(item: numberOfItems - 1, section: 0), at: UICollectionView.ScrollPosition(), animated: false)
                    
                    //MARK: -
//                    let numberOfRows = totalListVC.totalListTableView.numberOfRows(inSection: 0)
//                    totalListVC.totalListTableView.scrollToRow(at: IndexPath(row: numberOfRows - 1, section: 0), at: UITableView.ScrollPosition.top, animated: false)
//                    
                    totalListVC.totalListView.layoutIfNeeded()
                    
                    
                    selectedCell = totalListVC.totalListCollectionView.cellForItem(at: IndexPath(item: numberOfItems - 1, section: 0)) as! TotalListCollectionViewCell
                    
                    //MARK: -
//                    selectedCell = totalListVC.totalListTableView.cellForRow(at: IndexPath(row: numberOfRows - 1, section: 0)) as! TotalListTableViewCell
                    
                } else {
                    
                    
                    selectedCell = totalListVC.totalListCollectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as! TotalListCollectionViewCell
                    
                    //MARK: -
//                    selectedCell = totalListVC.totalListTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! TotalListTableViewCell
                    
                }
                
                
                
            } else if userDefaultCriterion == OrderCriterion.creationDate.rawValue {
                
                
                selectedCell = totalListVC.totalListCollectionView.cellForItem(at: popupCardVC.selectedIndexPath) as! TotalListCollectionViewCell
                
                //MARK: -
//                selectedCell = totalListVC.totalListTableView.cellForRow(at: popupCardVC.selectedIndexPath) as! TotalListTableViewCell
                
            } else {
                if popupCardView.isTextFieldChanged {
                    self.dismissalPropertyAnimatorForBars.addAnimations {
                        naviCon.navigationBar.bounds.origin.y = 0
                        tabBarCon.tabBar.frame.origin.y = screenSize.height - tabBarCon.tabBar.frame.height
                    }
                    
                    self.dismissalPropertyAnimator.addAnimations {
                        popupCardView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                        popupCardView.alpha = 0
                        popupCardView.layoutIfNeeded()
                    }
                    
                    self.dismissalPropertyAnimator.addCompletion { position in
                        transitionContext.completeTransition(true)
                    }
                    
                    dismissalPropertyAnimator.startAnimation()
                    dismissalPropertyAnimatorForBars.startAnimation()
                    
                    return
                } else {
                    
                    
                    selectedCell = totalListVC.totalListCollectionView.cellForItem(at: popupCardVC.selectedIndexPath) as! TotalListCollectionViewCell
                    
                    //MARK: - 
//                    selectedCell = totalListVC.totalListTableView.cellForRow(at: popupCardVC.selectedIndexPath) as! TotalListTableViewCell
                }
            }
        
        }
         */
        
        selectedCell.heartImageView.image = popupCardVC.memoEntity.isFavorite ? UIImage(systemName: "heart.fill") : UIImage(systemName: "heart")
        popupCardView.selectedImageCollectionViewHeightConstraint.constant = popupCardView.numberOfImages == 0 ? 0 : 70
        
        
        selectedCell.alpha = 0
        convertedRect = selectedCell.convert(selectedCell.contentView.frame, to: totalListVC.totalListView)
        
        
        
        self.dismissalPropertyAnimator.addAnimations {
            popupCardView.frame = convertedRect
            popupCardView.layer.cornerRadius = 20
            popupCardView.titleTextFieldTopConstraint.constant = 6
            popupCardView.titleTextFieldLeadingConstraint.constant = 15
            
            popupCardView.heartImageViewTrailingConstraint.isActive = false
            popupCardView.heartImageViewTrailingToPopupCardViewConstraint.isActive = true
            popupCardView.heartImageViewTopConstraint.constant = 10
            popupCardView.heartImageViewLeadingConstraint.constant = 10
            popupCardView.heartImageViewTrailingConstraint.constant = -10
            popupCardView.heartImageViewWidthConstraint.constant = 30
            popupCardView.heartImageViewHeightConstraint.constant = 30
            
            popupCardView.selectedImageCollectionViewTopConstraint.constant = 0
            popupCardView.selectedImageCollectionViewHeightConstraint.constant = 0
            popupCardView.memoTextViewLeadingConstraint.constant = 10
            popupCardView.memoTextViewTrailingConstraint.constant = -10
            popupCardView.memoTextView.showsVerticalScrollIndicator = false
            popupCardView.memoTextView.layer.cornerRadius = 0
//            이렇게 bounds.origin.y = 0 으로 할당하면 textView의 맨 위로 올라갈 것 같지만, 현재 로딩돼있는 content의 제일 위로만 가는 것 같음.
//            어쨌든 UITextView도 UIScrollView이다 보니, 아마 dequeue 하는 형식으로 진행될 것 같음.
//            if popupCardView.memoTextView.contentOffset.y > 0 {
            popupCardView.categoryCollectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
            popupCardView.memoTextView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
//            }
//            popupCardView.memoTextView.bounds.origin = CGPoint(x: 0, y: 0)
            
            
            let shadowPathAnimation: CABasicAnimation = {
                
                let path = UIBezierPath(roundedRect: selectedCell.contentView.bounds, cornerRadius: 13)
                
                let animation = CABasicAnimation(keyPath: "shadowPath")
                animation.toValue = path.cgPath
                animation.timingFunction = CAMediaTimingFunction(controlPoints: 0.46, 1.32, 0.31, 1)
//                animation.timingFunction = CAMediaTimingFunction(controlPoints: 0, 0, 1, 1)
                animation.duration = 0.1
                animation.autoreverses = false
                animation.isRemovedOnCompletion = false
                animation.fillMode = .forwards
                return animation
            }()
            popupCardView.layer.add(shadowPathAnimation, forKey: "shadowPathAnimation")
            
//            let path = UIBezierPath(roundedRect: selectedCell.contentView.bounds, cornerRadius: 13)
//            popupCardView.layer.shadowPath = path.cgPath
            
            
            let shadowColorAnimation: CASpringAnimation = {
                let animation = CASpringAnimation(keyPath: "shadowColor")
                
                if popupCardView.traitCollection.userInterfaceStyle == .dark {
                    animation.toValue = UIColor.clear.cgColor
                } else {
                    animation.toValue = UIColor.currentTheme().cgColor
                }
                
                animation.initialVelocity = 0
                animation.mass = 0.7
                animation.stiffness = 400
                animation.damping = 200
                
                animation.autoreverses = false
                animation.isRemovedOnCompletion = false
                animation.fillMode = .forwards
                return animation
            }()
            popupCardView.layer.add(shadowColorAnimation, forKey: "shadowColorAnimation")
            
            
            let shadowOpacityAnimation: CASpringAnimation = {
                let animation = CASpringAnimation(keyPath: "shadowOpacity")
                animation.toValue = 0.1

                animation.initialVelocity = 0
                animation.mass = 0.7
                animation.stiffness = 400
                animation.damping = 200
                
                animation.autoreverses = false
                animation.isRemovedOnCompletion = false
                animation.fillMode = .forwards
                return animation
            }()
            popupCardView.layer.add(shadowOpacityAnimation, forKey: "shadowOpacityAnimation")
            
            let shadowRadiusAnimation: CASpringAnimation = {
                let animation = CASpringAnimation(keyPath: "shadowRadius")
                animation.toValue = 8
                
                animation.initialVelocity = 0
                animation.mass = 0.7
                animation.stiffness = 400
                animation.damping = 200
                
                animation.autoreverses = false
                animation.isRemovedOnCompletion = false
                animation.fillMode = .forwards
                return animation
            }()
            popupCardView.layer.add(shadowRadiusAnimation, forKey: "shadowRadiusAnimation")
            
            
            
            popupCardView.layoutIfNeeded()
        }
        
        
        self.dismissalPropertyAnimator.addAnimations({
            
        }, delayFactor: 0.2)
        
        
        //아래 클로저에서 selectedCell을 캡처하게 되는데(애니메이션이라 함수 실행이 끝나고도 붙들고 있어야 함), selectedCell은 참조 타입이라서 클로저에서 캡처하게 되면, 메모리 주소를 캡처하게 된다.
        //(값 타입일 때 복사한 값을 캡처하게 되는 것ㅇㅇ)
        //만약 아래 클로저에서 캡처리스트를 사용하여 selectedCell을 캡처한다면
        //selectedCell에 접근할 때 캡처된 메모리 주소를 거치지 않고 직접 selectedCell에 접근하는 게 되는 것임...(캡처리스트 개념 명확히!!)
        self.dismissalPropertyAnimator.addAnimations({
//            popupCardView.alpha = 1
//            popupCardView.layer.shadowOpacity = 0
//            selectedCell.alpha = 1
        }, delayFactor: 0.6)
        
        self.dismissalPropertyAnimator.addCompletion { animatingPosition in
            selectedCell.alpha = 1
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        self.dismissalPropertyAnimator.startAnimation()
        self.dismissalPropertyAnimatorForBars.startAnimation()
    }
    
    
    
}

