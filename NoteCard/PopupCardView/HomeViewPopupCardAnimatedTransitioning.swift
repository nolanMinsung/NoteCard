//
//  PopupCardAnimatedTransitioning.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit




enum AnimationType {
    case present
    case dismiss
}

final class HomeViewPopupCardAnimatedTransitioning: NSObject {
    
    let screenSize = UIScreen.current?.bounds.size
    
    let presentationPropertyAnimator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 0.85)
    let presentationPropertyAnimatorForSnapshot = UIViewPropertyAnimator(duration: 0.1, dampingRatio: 1)
    
//    let presentationPropertyAnimatorForBars: UIViewPropertyAnimator = {
//        let animator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1)
//        animator.isInterruptible = true
//        return animator
//    }()
    
    let dismissalPropertyAnimator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 0.8)
    let dismissalPropertyForPopupCardSnapshot = UIViewPropertyAnimator(duration: 0.25, dampingRatio: 1)
    let dismissalPropertyAnimatorForBars = UIViewPropertyAnimator(duration: 0.8, dampingRatio: 1)
    
    let disappearingPropertyAnimator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1)
    
    var userDefaultCriterion: String? { UserDefaults.standard.string(forKey: KeysForUserDefaults.orderCriterion.rawValue) }
    
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


extension HomeViewPopupCardAnimatedTransitioning: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 2
    }
    
    
    /*
    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        //interruptibleAnimator은 dismiss 시에만 쓰는 것으로 가정하였으므로 fromVC 가 사실상 popupCardVC임.
        //이 아래 guard문에 fataError() 넣으니까 present 할 때 에러뜨네...? -> 이유 분석!!
        guard let popupCardVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? PopupCardViewController else { return UIViewPropertyAnimator() }
        guard let tabBarCon = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? UITabBarController else { return UIViewPropertyAnimator() }
        guard let naviCon = tabBarCon.selectedViewController as? UINavigationController else { return UIViewPropertyAnimator() }
        
        let selectedCellFrame = popupCardVC.selectedCellFrame
        
        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.7)
        
        animator.addAnimations { [weak tabBarCon, weak popupCardVC] in
            guard let tabBarCon else { fatalError() }
            guard let popupCardVC else { fatalError() }
            tabBarCon.view.alpha = 1.0
            popupCardVC.view.frame = selectedCellFrame
            let popupCardView = popupCardVC.view as! PopupCardView
            popupCardView.memoTitleLabelTopConstraint.constant = 6
            popupCardView.memoTitleLabelLeadingConstraint.constant = 15
            popupCardView.selectedImageCollectionViewHeightConstraint.constant = 0
            popupCardView.memoTextViewLeadingConstraint.constant = 15
            popupCardView.memoTextViewTrailingConstraint.constant = -15
            popupCardView.memoTextView.bounds.origin = CGPoint(x: 0, y: 0)
            popupCardVC.view.layer.cornerRadius = 20
            popupCardView.layoutIfNeeded()
//            popupCardView.selectedImageCollectionView.frame.size = CGSize(width: 0, height: 0)
            
        }
        
        //내비게이션바와 탭바를 화면 안쪽으로 들여오는 코드
        animator.addAnimations({
            popupCardVC.view.alpha = 1
            naviCon.navigationBar.bounds.origin.y = 0
            tabBarCon.tabBar.frame.origin.y = 844 - tabBarCon.tabBar.frame.height
            
        }, delayFactor: 0.5)
        
        
        animator.addCompletion { (position) in
            //애니메이션이 취소되지 않고 완료했음을 알리는 코드
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        return animator
    }
    */
    
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        print(#function)
        switch self.animationType {
        case .present:
            self.animationForPresentation(using: transitionContext)
        case .dismiss:
            self.animationForDismissal(using: transitionContext)
        }
        
    }
    
    
    
    private func animationForPresentation(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let screenSize else { return }
        
        guard let popupCardVC = transitionContext.viewController(forKey: .to) as? PopupCardViewController else { return }
        let selectedCellFrame = popupCardVC.selectedCellFrame
        let cornerRadius = popupCardVC.cornerRadius
        let containerView = transitionContext.containerView
        containerView.addSubview(popupCardVC.view)
        
        let popupCardView = popupCardVC.view as! PopupCardView
        weak var selectedCell = popupCardVC.selectedCollectionViewCell
        guard let selectedCell else { fatalError() }
        popupCardView.frame = selectedCellFrame
        popupCardView.layer.cornerRadius = cornerRadius
        popupCardView.selectedImageCollectionViewTopConstraint.constant = 0
        popupCardView.selectedImageCollectionViewHeightConstraint.constant = 0
        popupCardView.titleTextFieldTopConstraint.constant = 10
        popupCardView.titleTextFieldLeadingConstraint.constant = 15
        popupCardView.memoTextViewLeadingConstraint.constant = 15
        popupCardView.memoTextViewTrailingConstraint.constant = -15
        popupCardView.layoutIfNeeded()
        
        let cellSnapshot: UIView = {
            guard let cellSnapshot = selectedCell.contentView.snapshotView(afterScreenUpdates: false) else { fatalError() }
            cellSnapshot.backgroundColor = .memoBackground
            cellSnapshot.layer.cornerRadius = cornerRadius
            cellSnapshot.layer.cornerCurve = .continuous
            cellSnapshot.translatesAutoresizingMaskIntoConstraints = false
            return cellSnapshot
        }()
        
        popupCardView.cellSnapshot = cellSnapshot
        popupCardView.addSubview(popupCardView.cellSnapshot)
        cellSnapshot.topAnchor.constraint(equalTo: popupCardView.topAnchor, constant: 0).isActive = true
        cellSnapshot.leadingAnchor.constraint(equalTo: popupCardView.leadingAnchor, constant: 0).isActive = true
        cellSnapshot.trailingAnchor.constraint(equalTo: popupCardView.trailingAnchor, constant: 0).isActive = true
        cellSnapshot.bottomAnchor.constraint(equalTo: popupCardView.bottomAnchor, constant: 0).isActive = true
        
        guard let fromVC = transitionContext.viewController(forKey: .from) as? UITabBarController else { fatalError() }
        guard let selectedNaviCon = fromVC.selectedViewController as? UINavigationController else { fatalError() }
        self.presentationPropertyAnimator.addAnimations {
            fromVC.view.alpha = 0.5
            fromVC.tabBar.bounds.origin.y = -(fromVC.tabBar.bounds.height + fromVC.view.safeAreaInsets.bottom)
            selectedNaviCon.navigationBar.bounds.origin.y = selectedNaviCon.navigationBar.frame.height + 47
        }
        
        self.presentationPropertyAnimator.addAnimations {
            guard let screenRect = popupCardView.window?.windowScene?.screen.bounds else { fatalError() }
            let screenWidth = screenRect.width
            let screenHeight = screenRect.height
            let horizontalInset: CGFloat = screenWidth / 40
            let verticalInset: CGFloat = screenHeight * 0.145
            popupCardView.frame = CGRect(x: horizontalInset, y: verticalInset, width: screenWidth - (horizontalInset * 2), height: screenHeight - (verticalInset * 2))
            popupCardView.layer.cornerRadius = 37
            popupCardView.layer.cornerCurve = .continuous
            popupCardView.titleTextFieldTopConstraint.constant = 10
            popupCardView.titleTextFieldLeadingConstraint.constant = 20
            
//            switch popupCardView.numberOfImages {
//            case 0:
//                popupCardView.selectedImageCollectionViewHeightConstraint.constant = 0
//            default:
//                popupCardView.selectedImageCollectionViewHeightConstraint.constant = 70
//            }
            
            popupCardView.selectedImageCollectionViewTopConstraint.constant = 6
            popupCardView.selectedImageCollectionViewHeightConstraint.constant = popupCardView.numberOfImages == 0 ? 0 : 70
            
            popupCardView.memoTextViewLeadingConstraint.constant = 10
            popupCardView.memoTextViewTrailingConstraint.constant = -10
            popupCardView.memoTextView.bounds.origin.x = 0
            popupCardView.layoutIfNeeded()
        }
        self.presentationPropertyAnimator.addCompletion { animatingPosition in transitionContext.completeTransition(true) }
        
        self.presentationPropertyAnimatorForSnapshot.addAnimations {
            cellSnapshot.alpha = 0
        }
        
        self.presentationPropertyAnimator.startAnimation()
        self.presentationPropertyAnimatorForSnapshot.startAnimation()
    }
    
    
    
    
    
    
//---------------------------------------------------------------------------------------------------------------------
    
    
    
    
    
    
    
    private func animationForDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let screenSize else { return }
        guard let popupCardVC = transitionContext.viewController(forKey: .from) as? PopupCardViewController else { return }
        
        guard let tabBarCon = transitionContext.viewController(forKey: .to) as? UITabBarController else { fatalError() }
        guard let naviCon = tabBarCon.selectedViewController as? UINavigationController else { fatalError() }
        guard let homeVC = naviCon.topViewController as? HomeViewController else { fatalError() }
        guard let homeView = homeVC.view as? HomeView else { fatalError() }
        
//        let selectedCell = popupCardVC.selectedCell
//        let selectedCellFrame = popupCardVC.selectedCellFrame
        
        weak var popupCardView = popupCardVC.view as? PopupCardView
        guard let popupCardView else { fatalError() }
        //guard let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? UITabBarController else { return }
        //guard let selectedNaviCon = toVC.selectedViewController as? UINavigationController else { return }
        
//        var selectedCell: HomeCollectionViewFavoriteCell
        weak var selectedCell: UICollectionViewCell?
        
        
        
        self.disappearingPropertyAnimator.addAnimations {
            popupCardView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            popupCardView.alpha = 0
            tabBarCon.view.alpha = 1.0
            popupCardView.layoutIfNeeded()
        }
        
        self.disappearingPropertyAnimator.addCompletion { position in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        self.dismissalPropertyAnimatorForBars.addAnimations({
            naviCon.navigationBar.bounds.origin.y = 0
            tabBarCon.tabBar.bounds.origin.y = 0
        }, delayFactor: 0.5)
        
        
        
        
        if self.userDefaultCriterion == OrderCriterion.modificationDate.rawValue {
            
            let isOrderAscending = UserDefaults.standard.bool(forKey: KeysForUserDefaults.isOrderAscending.rawValue)
            
            if isOrderAscending && popupCardView.isEdited {
                self.disappearingPropertyAnimator.startAnimation()
                self.dismissalPropertyAnimatorForBars.startAnimation()
                return
                
            } else {
                switch (popupCardView.isEdited, popupCardVC.selectedIndexPath.section) {
                case (true, 1):
                    homeView.homeCollectionView.scrollToItem(at: IndexPath(item: 0, section: 1), at: .init(), animated: false)
                    homeView.layoutIfNeeded()
                    selectedCell = homeView.homeCollectionView.cellForItem(at: IndexPath(row: 0, section: 1)) as! HomeFavoriteCell
                case (true, 2):
                    homeView.homeCollectionView.scrollToItem(at: IndexPath(item: 0, section: 2), at: .init(), animated: false)
                    homeView.layoutIfNeeded()
                    selectedCell = homeView.homeCollectionView.cellForItem(at: IndexPath(row: 0, section: 2)) as! HomeRecentCell
                case (false, 1):
                    selectedCell = homeView.homeCollectionView.cellForItem(at: popupCardVC.selectedIndexPath) as! HomeFavoriteCell
                case (false, 2):
                    selectedCell = homeView.homeCollectionView.cellForItem(at: popupCardVC.selectedIndexPath) as! HomeRecentCell
                default:
                    fatalError()
                }
            }
            
            
        } else {
            switch popupCardVC.selectedIndexPath.section {
            case 1:
                selectedCell = homeView.homeCollectionView.cellForItem(at: popupCardVC.selectedIndexPath) as! HomeFavoriteCell
            case 2:
                selectedCell = homeView.homeCollectionView.cellForItem(at: popupCardVC.selectedIndexPath) as! HomeRecentCell
            default:
                fatalError()
            }
            
        }
        
//        if popupCardView.isEdited {
//            homeView.homeCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .init(), animated: false)
//            homeView.homeCollectionView.layoutIfNeeded()
//            selectedCell =
//            popupCardVC.selectedIndexPath.section == 1 ?
//            homeView.homeCollectionView.cellForItem(at: IndexPath(row: 0, section: 1)) as! HomeCollectionViewFavoriteCell :
//            homeView.homeCollectionView.cellForItem(at: IndexPath(row: 0, section: 2)) as! HomeCollectionViewRecentCell
//
//        } else {
//            selectedCell =
//            popupCardVC.selectedIndexPath.section == 1 ?
//            homeView.homeCollectionView.cellForItem(at: popupCardVC.selectedIndexPath) as! HomeCollectionViewFavoriteCell :
//            homeView.homeCollectionView.cellForItem(at: popupCardVC.selectedIndexPath) as! HomeCollectionViewRecentCell
//        }
        
//
//        let cellSnapshot: UIView = { [weak selectedCell] in
//            guard let selectedCell else { fatalError() }
//            guard let snapshot = selectedCell.snapshotView(afterScreenUpdates: true) else { fatalError() }
//            snapshot.translatesAutoresizingMaskIntoConstraints = false
//            return snapshot
//        }()
//
//        popupCardView.cellSnapshot.removeFromSuperview()
//        popupCardView.addSubview(cellSnapshot)
//        cellSnapshot.topAnchor.constraint(equalTo: popupCardView.topAnchor, constant: 0).isActive = true
//        cellSnapshot.leadingAnchor.constraint(equalTo: popupCardView.leadingAnchor, constant: 0).isActive = true
//        cellSnapshot.trailingAnchor.constraint(equalTo: popupCardView.trailingAnchor, constant: 0).isActive = true
//        cellSnapshot.bottomAnchor.constraint(equalTo: popupCardView.bottomAnchor, constant: 0).isActive = true
//
//
        
//        var convertedRect = selectedCell.convert(selectedCell.contentView.frame, to: homeVC.homeView)
        
        
//        guard let cellSnapshot = selectedCell.snapshotView(afterScreenUpdates: false) else { fatalError() }
//        cellSnapshot.translatesAutoresizingMaskIntoConstraints = false
//        
//        //        popupCardView.cellSnapshot.removeFromSuperview()
//        popupCardView.addSubview(cellSnapshot)
//        cellSnapshot.topAnchor.constraint(equalTo: popupCardView.topAnchor, constant: 0).isActive = true
//        cellSnapshot.leadingAnchor.constraint(equalTo: popupCardView.leadingAnchor, constant: 0).isActive = true
//        cellSnapshot.trailingAnchor.constraint(equalTo: popupCardView.trailingAnchor, constant: 0).isActive = true
//        cellSnapshot.bottomAnchor.constraint(equalTo: popupCardView.bottomAnchor, constant: 0).isActive = true
        
        
        guard let selectedCell else { fatalError() }
        selectedCell.alpha = 0
        
        let popupCardSnapshot: UIView = { [weak popupCardView] in
            guard let popupCardView else { fatalError() }
            guard let snapshot = popupCardView.snapshotView(afterScreenUpdates: false) else { fatalError() }
            snapshot.layer.cornerRadius = 37
            snapshot.translatesAutoresizingMaskIntoConstraints = false
            return snapshot
        }()
        
        popupCardView.popupCardSnapshot = popupCardSnapshot
        popupCardView.addSubview(popupCardView.popupCardSnapshot)
        popupCardSnapshot.topAnchor.constraint(equalTo: popupCardView.topAnchor, constant: 0).isActive = true
        popupCardSnapshot.leadingAnchor.constraint(equalTo: popupCardView.leadingAnchor, constant: 0).isActive = true
        popupCardSnapshot.trailingAnchor.constraint(equalTo: popupCardView.trailingAnchor, constant: 0).isActive = true
        popupCardSnapshot.bottomAnchor.constraint(equalTo: popupCardView.bottomAnchor, constant: 0).isActive = true
        popupCardView.cellSnapshot.alpha = 1
        
        popupCardView.layer.shadowOpacity = 0
        popupCardView.layer.shadowRadius = 0
        popupCardView.layer.shadowColor = UIColor.black.cgColor
        popupCardView.layoutIfNeeded()
        
        self.dismissalPropertyAnimator.addAnimations { [weak tabBarCon, weak popupCardView, weak selectedCell] in
            guard let tabBarCon else { fatalError() }
            guard let popupCardView else { fatalError() }
            guard let selectedCell else { fatalError() }
            
            tabBarCon.view.alpha = 1.0
            popupCardView.frame = selectedCell.convert(selectedCell.contentView.frame, to: homeVC.homeView)
            popupCardView.titleTextFieldTopConstraint.constant = 6
            popupCardView.titleTextFieldLeadingConstraint.constant = 15
            popupCardView.ellipsisButton.alpha = 0
            popupCardView.selectedImageCollectionViewTopConstraint.constant = 0
            popupCardView.selectedImageCollectionViewHeightConstraint.constant = 0
            popupCardView.memoTextViewLeadingConstraint.constant = 15
            popupCardView.memoTextViewTrailingConstraint.constant = -15
            popupCardView.layer.cornerRadius = 20
            
            let shadowPathAnimation: CABasicAnimation = {
                let path = UIBezierPath(roundedRect: selectedCell.bounds, cornerRadius: 13)
                
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
            
//            let path = UIBezierPath(roundedRect: selectedCell.bounds, cornerRadius: 13)
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
                animation.toValue = 0.2

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
                animation.toValue = 5
                
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
        }
        
        self.dismissalPropertyAnimator.addCompletion { _ in
            selectedCell.alpha = 1
        }
        
        self.dismissalPropertyForPopupCardSnapshot.addAnimations({
            popupCardView.popupCardSnapshot.alpha = 0
        }, delayFactor: 0.52)
        
        self.dismissalPropertyAnimator.addAnimations({
            popupCardVC.view.alpha = 1
        }, delayFactor: 0.6)
        
        self.dismissalPropertyAnimator.addCompletion { animatingPosition in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        
        if !popupCardVC.memoEntity.isInTrash {
            self.dismissalPropertyAnimator.startAnimation()
            self.dismissalPropertyForPopupCardSnapshot.startAnimation()
        } else {
            self.disappearingPropertyAnimator.startAnimation()
        }
        
        self.dismissalPropertyAnimatorForBars.startAnimation()
    }
    
    
}

