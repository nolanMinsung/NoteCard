//
//  MemoViewPopupCardAnimatedTransitioning.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/27.
//
import UIKit


/*
 enum AnimationType {
     case present
     case dismiss
 }
*/


final class MemoViewPopupCardAnimatedTransitioning: NSObject {
    
    
    
    var userDefaultCriterion: String? { UserDefaults.standard.string(forKey: UserDefaultsKeys.orderCriterion.rawValue) }
    
//    static let newGradientLayer: CAGradientLayer = {
//        let layer = CAGradientLayer()
//        layer.colors = [UIColor.white.withAlphaComponent(0).cgColor, UIColor.white.withAlphaComponent(0).cgColor]
////            layer.frame = memoView.blurView.bounds
//        layer.startPoint = CGPoint(x: 0.5, y: 0.0)
//        layer.endPoint = CGPoint(x: 0.5, y: 1.0)
//        layer.type = .axial
//        return layer
//    }()
    
    
    let screenSize = UIScreen.current?.bounds.size
//    lazy var screenWidth = self.screenSize?.width
//    lazy var screenHeight = self.screenSize?.height
    
    let presentationPropertyAnimator: UIViewPropertyAnimator = {
        let animator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 0.85)
        return animator
    }()
    
    let presentationPropertyAnimatorForSnapshot: UIViewPropertyAnimator = {
        let animator = UIViewPropertyAnimator(duration: 0.1, dampingRatio: 1)
        return animator
    }()
    
//    let presentationPropertyAnimatorForBars: UIViewPropertyAnimator = {
//        let animator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1)
//        animator.isInterruptible = true
//        return animator
//    }()
    
    let dismissalPropertyAnimator: UIViewPropertyAnimator = {
        let animator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 0.8)
        return animator
    }()
    
    let dismissalPropertyAnimatorForBars: UIViewPropertyAnimator = {
        let animator = UIViewPropertyAnimator(duration: 0.8, dampingRatio: 1)
        return animator
    }()
    
    let dismissalPropertyAnimatorForBlurView: UIViewPropertyAnimator = {
        let animator = UIViewPropertyAnimator(duration: 0.8, curve: UIView.AnimationCurve.linear)
        return animator
    }()
    
    let dismissalPropertyAnimatorForGradientView: UIViewPropertyAnimator = {
        let animator = UIViewPropertyAnimator(duration: 1.6, curve: UIView.AnimationCurve.linear)
        return animator
    }()
    
    let dismissalPropertyAnimatorForPopupCardSnapshot: UIViewPropertyAnimator = {
        let animator = UIViewPropertyAnimator(duration: 0.25, dampingRatio: 1)
        return animator
    }()
    
    
    let disappearingPropertyAnimator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1)
    
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


extension MemoViewPopupCardAnimatedTransitioning: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 2
    }
    
    
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
        
        guard let tabBarCon = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? UITabBarController else { fatalError() }
        guard let naviCon = tabBarCon.selectedViewController as? UINavigationController else { fatalError() }
        guard let memoVC = naviCon.topViewController as? MemoViewController else { fatalError() }
        guard let popupCardVC = transitionContext.viewController(forKey: .to) as? PopupCardViewController else { fatalError() }
        
        let memoView = memoVC.view as! MemoView
        let popupCardView = popupCardVC.view as! PopupCardView
        let selectedCellFrame = popupCardVC.selectedCellFrame
        let cornerRadius = popupCardVC.cornerRadius
        let containerView = transitionContext.containerView
//        let selectedCell: UICollectionViewCell!
        let selectedCell = popupCardVC.selectedCollectionViewCell
        
        containerView.addSubview(popupCardView)
        
        popupCardView.frame = selectedCellFrame
        popupCardView.layer.cornerRadius = cornerRadius
        popupCardView.titleTextFieldTopConstraint.constant = 10
        popupCardView.titleTextFieldLeadingConstraint.constant = 15
        popupCardView.selectedImageCollectionViewTopConstraint.constant = 0
        popupCardView.selectedImageCollectionViewHeightConstraint.constant = 0
        popupCardView.memoTextViewLeadingConstraint.constant = 15
        popupCardView.memoTextViewTrailingConstraint.constant = -15
        popupCardView.memoDateLabel.alpha = 0
        
        if memoVC.isEditing {
//            popupCardView.titleTextFieldTapGesture.isEnabled = false
            popupCardView.titleTextField.isEnabled = false
            popupCardView.heartImageView.isUserInteractionEnabled = false
            popupCardView.heartImageView.tintColor = .lightGray
            popupCardView.ellipsisButton.isEnabled = false
            popupCardView.memoTextViewTapGesture.isEnabled = false
            popupCardView.memoTextView.isSelectable = false
        }
        
        
        let cellSnapshot: UIView = {
            guard let cellSnapshot = selectedCell.contentView.snapshotView(afterScreenUpdates: false) else { fatalError() }
            cellSnapshot.backgroundColor = .memoBackground
            cellSnapshot.layer.cornerRadius = cornerRadius
            cellSnapshot.layer.cornerCurve = .continuous
            cellSnapshot.translatesAutoresizingMaskIntoConstraints = false
            return cellSnapshot
        }()
        
//        아래처럼 적으면 스냅샷이 들어가긴 함....
//        popupCardView.addSubview(cellSnapshot)
        popupCardView.cellSnapshot = cellSnapshot
        popupCardView.addSubview(popupCardView.cellSnapshot)
        //PopupCardView의 viewForSnapshot은 강제 언래핑 타입이기 때문에, 위처럼 값을 할당한 후에 addSubView 해주지 않으면 에러가 발생할 수 있음.
        //(근데 어차피 viewForSnapshot에 새로 할당한 인스턴스를 addSubView해야 하기 때문에, 굳이 꼭 타입 때문만은 아니라도 여기서 addSubview해야하긴 함.
        //+추가로, snapshot이 popupCardView 의 subView 중에서 제일 위에 와야 하므로 제일 나중에 추가하는게 적절함.
        
        let snapshotTopConstraint = cellSnapshot.topAnchor.constraint(equalTo: popupCardView.topAnchor, constant: 0)
        let snapshotLeadingConstraint = cellSnapshot.leadingAnchor.constraint(equalTo: popupCardView.leadingAnchor, constant: 0)
        let snapshotTrailingConstraint = cellSnapshot.trailingAnchor.constraint(equalTo: popupCardView.trailingAnchor, constant: 0)
        let snapshotBottomConstraint = cellSnapshot.bottomAnchor.constraint(equalTo: popupCardView.bottomAnchor, constant: 0)
        
        snapshotTopConstraint.isActive = true
        snapshotLeadingConstraint.isActive = true
        snapshotTrailingConstraint.isActive = true
        snapshotBottomConstraint.isActive = true
        
        popupCardView.layoutIfNeeded()
        
        //TabBar가 있을 때
        guard let tabBarCon = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? UITabBarController else { return }
        guard let selectedNaviCon = tabBarCon.selectedViewController as? UINavigationController else { return }
        guard let memoVC = selectedNaviCon.topViewController as? MemoViewController else { return }
        let blurView = memoView.blurView
        let viewUnderNaviBar = memoView.viewUnderNaviBar
        
        
//        selectedCell.alpha = 0
        if #available(iOS 16.0, *) {
            memoVC.deleteBarButtonItem.isHidden = true
            memoVC.ellipsisBarButtonItem.isHidden = true
            
        } else {
//            memoVC.deleteBarButtonItem.isHidden = true
//            memoVC.ellipsisBarButtonItem.isHidden = true
        }
        
        memoVC.memoView.smallCardCollectionViewBottomConstraint.constant = 0
        
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
            
            tabBarCon.view.alpha = 0.5
            tabBarCon.tabBar.frame.origin.y = screenSize.height
            selectedNaviCon.navigationBar.bounds.origin.y = selectedNaviCon.navigationBar.frame.height + 47
            selectedNaviCon.toolbar.bounds.origin.y = -(selectedNaviCon.toolbar.bounds.height + memoVC.view.safeAreaInsets.bottom)
            
            print(selectedNaviCon.toolbar.bounds.height + memoVC.view.safeAreaInsets.bottom)
            print(selectedNaviCon.toolbar.bounds.height)
            
//            tabBarCon.view.alpha = 0.5
//            tabBarCon.tabBar.frame.origin.y = screenSize.height
//            selectedNaviCon.navigationBar.bounds.origin.y = selectedNaviCon.navigationBar.frame.height + 47
//            selectedNaviCon.toolbar.bounds.origin.y = -(selectedNaviCon.toolbar.bounds.height + 34)
            
            
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
            
            blurView.effect = .none
            viewUnderNaviBar.alpha = 0
        }
        
        self.presentationPropertyAnimator.addAnimations({
            popupCardView.memoDateLabel.alpha = 1
        }, delayFactor: 0.4)
        
        self.presentationPropertyAnimator.addCompletion { animatingPosition in
            transitionContext.completeTransition(true) }
        
        
        self.presentationPropertyAnimatorForSnapshot.addAnimations {
//            cellSnapshot.alpha = 0
            popupCardView.cellSnapshot.alpha = 0
        }
        
        
        self.presentationPropertyAnimator.startAnimation()
        self.presentationPropertyAnimatorForSnapshot.startAnimation()
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
//--------------------------------------------------------------------------------------------------------------------------------
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    private func animationForDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let userDefaultCriterion else { fatalError() }
        guard let screenSize else { fatalError() }
        guard let popupCardVC = transitionContext.viewController(forKey: .from) as? PopupCardViewController else { fatalError() }
        guard let popupCardView = popupCardVC.view as? PopupCardView else { fatalError() }
        
        guard let tabBarCon = transitionContext.viewController(forKey: .to) as? UITabBarController else { return }
        guard let selectedNaviCon = tabBarCon.selectedViewController as? UINavigationController else { return }
        guard let memoVC = selectedNaviCon.topViewController as? MemoViewController else { return }
        guard let memoView = memoVC.view as? MemoView else { return }
        
        let popupCardSnapshot: UIView = {
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
        
        //        var convertedRect: CGRect = .zero
        
        var selectedCell: SmallCardCollectionViewCell?
        
        if memoVC.memoEntitiesArray.contains(popupCardVC.memoEntity) {
            selectedCell = memoVC.smallCardCollectionView.cellForItem(at: popupCardVC.selectedIndexPath) as? SmallCardCollectionViewCell
        } else {
            selectedCell = nil
        }
        
        /*
        if popupCardView.isEdited,
           memoVC.memoEntitiesArray.contains(popupCardVC.memoEntity),
           userDefaultCriterion == OrderCriterion.modificationDate.rawValue {
            selectedCell = memoVC.smallCardCollectionView.cellForItem(at: popupCardVC.selectedIndexPath) as? SmallCardCollectionViewCell
                
        } else if popupCardView.isEdited,
                  memoVC.memoEntitiesArray.contains(popupCardVC.memoEntity),
                  userDefaultCriterion == OrderCriterion.creationDate.rawValue {
            selectedCell = memoVC.smallCardCollectionView.cellForItem(at: popupCardVC.selectedIndexPath) as? SmallCardCollectionViewCell
            
        } else if popupCardView.isEdited, !memoVC.memoEntitiesArray.contains(popupCardVC.memoEntity) {
            selectedCell = nil
            
        } else if !popupCardView.isEdited, memoVC.memoEntitiesArray.contains(popupCardVC.memoEntity) {
            print(popupCardVC.selectedIndexPath)
//            selectedCell = memoVC.smallCardCollectionView.cellForItem(at: popupCardVC.selectedIndexPath) as? SmallCardCollectionViewCell
//            guard let selectedCell else { fatalError() }
            selectedCell = popupCardVC.selectedCollectionViewCell as? SmallCardCollectionViewCell
        }
         */
        
        
        
        
        tabBarCon.view.alpha = 1.0
        
        memoView.categoryNameTextFieldTopConstraint.constant = -200
        
//        let newBlurView: UIVisualEffectView = {
//            let view = UIVisualEffectView()
//            view.translatesAutoresizingMaskIntoConstraints = false
//            return view
//        }()
        
//        memoView.addSubview(newBlurView)
//        newBlurView.topAnchor.constraint(equalTo: memoView.topAnchor, constant: 0).isActive = true
//        newBlurView.leadingAnchor.constraint(equalTo: memoView.leadingAnchor, constant: 0).isActive = true
//        newBlurView.trailingAnchor.constraint(equalTo: memoView.trailingAnchor, constant: 0).isActive = true
//        newBlurView.heightAnchor.constraint(equalToConstant: 200).isActive = true
//        memoView.layoutSubviews()
//        
//        memoView.blurView = newBlurView
//        
//        memoView.insertSubview(newBlurView, aboveSubview: memoView.smallCardCollectionView)
        
        memoView.layoutSubviews()
        
        let blurView = memoView.blurView
        let viewUnderNaviBar = memoView.viewUnderNaviBar
//        blurView.effect = nil
        
        
        
        memoVC.memoView.smallCardCollectionViewBottomConstraint.constant = 0
        memoVC.smallCardCollectionView.clipsToBounds = false
        popupCardView.cellSnapshot.alpha = 1
        
        //아래 클로저에서 selectedCell을 캡처하게 되는데(애니메이션이라 함수 실행이 끝나고도 붙들고 있어야 함), selectedCell은 참조 타입이라서 클로저에서 캡처하게 되면, 메모리 주소를 캡처하게 된다.
        //(값 타입일 때 복사한 값을 캡처하게 되는 것ㅇㅇ)
        //만약 아래 클로저에서 캡처리스트를 사용하여 selectedCell을 캡처한다면
        //selectedCell에 접근할 때 캡처된 메모리 주소를 거치지 않고 직접 selectedCell에 접근하는 게 되는 것임...(캡처리스트 개념 명확히!!)
        self.dismissalPropertyAnimator.addAnimations {
            guard let selectedCell else { fatalError() }
            let convertedRect = selectedCell.convert(selectedCell.contentView.frame, to: memoVC.memoView)
            popupCardView.frame = convertedRect
            popupCardView.layer.cornerRadius = 13
            
            if selectedCell.isSelected {
                popupCardView.layer.borderColor = UIColor.currentTheme().cgColor
                popupCardView.layer.borderWidth = 2
            }
            
//            popupCardView.titleTextFieldTopConstraint.constant = 6
//            popupCardView.tiㄴ딛tleTextFieldLeadingConstraint.constant = 15
//            popupCardView.ellipsisButton.alpha = 0
//            popupCardView.selectedImageCollectionViewTopConstraint.constant = 0
//            popupCardView.selectedImageCollectionViewHeightConstraint.constant = 0
//            popupCardView.memoTextViewLeadingConstraint.constant = 15
//            popupCardView.memoTextViewTrailingConstraint.constant = -15
            
            
            popupCardView.titleTextField.alpha = 0 //iPhone SE(3rd Gen) 의 화면 비율에서는 팝업 카드가 작아질 때 titleTextField가 카드 밖으로 나와 보인다.
            
            popupCardView.layoutIfNeeded()
            
            
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
                
                if memoView.traitCollection.userInterfaceStyle == .dark {
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
                animation.toValue = 0.3

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
                animation.toValue = 4
                
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
        
        
        self.dismissalPropertyAnimator.addCompletion { animatingPosition in
            guard let selectedCell else { fatalError() }
            selectedCell.alpha = 1
            memoVC.smallCardCollectionView.clipsToBounds = true
            if #available(iOS 16.0, *) {
                memoVC.deleteBarButtonItem.isHidden = false
                memoVC.ellipsisBarButtonItem.isHidden = false
            } else {
//                memoVC.deleteBarButtonItem.isHidden = false
//                memoVC.ellipsisBarButtonItem.isHidden = false
            }
            
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        
        
        self.dismissalPropertyAnimatorForBars.addAnimations({
            selectedNaviCon.navigationBar.bounds.origin.y = 0
            selectedNaviCon.toolbar.bounds.origin.y = 0
            tabBarCon.tabBar.frame.origin.y = screenSize.height - tabBarCon.tabBar.frame.height
            memoView.categoryNameTextFieldTopConstraint.constant = 0
            memoView.layoutIfNeeded()
        }, delayFactor: 0.5)
        
        self.dismissalPropertyAnimatorForBlurView.addAnimations ({
            blurView.effect = UIBlurEffect(style: UIBlurEffect.Style.systemThickMaterial)
            viewUnderNaviBar.alpha = 1
        }, delayFactor: 0.5)
        
        
        
        self.dismissalPropertyAnimatorForPopupCardSnapshot.addAnimations ({
            popupCardView.popupCardSnapshot.alpha = 0
        }, delayFactor: 0.5)
        
        
        
        
        
        
        self.disappearingPropertyAnimator.addAnimations {
            popupCardView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            popupCardView.alpha = 0
            popupCardView.layoutIfNeeded()
        }
        
        self.disappearingPropertyAnimator.addCompletion { _ in
            memoVC.smallCardCollectionView.clipsToBounds = true
            if #available(iOS 16.0, *) {
                memoVC.deleteBarButtonItem.isHidden = false
                memoVC.ellipsisBarButtonItem.isHidden = false
            } else {
//                memoVC.deleteBarButtonItem.isHidden = false
//                memoVC.ellipsisBarButtonItem.isHidden = false
            }
            
            transitionContext.completeTransition(true)
        }
        
        
        
        if memoVC.memoEntitiesArray.contains(popupCardVC.memoEntity) {
            guard let selectedCell else { fatalError() }
            selectedCell.alpha = 0
            self.dismissalPropertyAnimator.startAnimation()
            self.dismissalPropertyAnimatorForPopupCardSnapshot.startAnimation()
        } else {
            self.disappearingPropertyAnimator.startAnimation()
        }
        
        self.dismissalPropertyAnimatorForBars.startAnimation()
        self.dismissalPropertyAnimatorForBlurView.startAnimation()
        self.dismissalPropertyAnimatorForGradientView.startAnimation()
        
    }
    
    
}
