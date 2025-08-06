//
//  TotalListViewPopupCardAnimatedTransitioning.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/26.
//


import UIKit

final class TotalListViewPopupCardAnimatedTransitioning: NSObject {
    
    var userDefaultCriterion: String? { UserDefaults.standard.string(forKey: UserDefaultsKeys.orderCriterion.rawValue) }
    
    let screenSize = UIScreen.current?.bounds.size
    let presentationPropertyAnimator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1)
    
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
        
        
        
        // popupCardView.frame = selectedCellFrame
        let popupCardInitialConstraints = [
            popupCardView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: selectedCellFrame.origin.y),
            popupCardView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: selectedCellFrame.origin.x),
            popupCardView.widthAnchor.constraint(equalToConstant: selectedCellFrame.width),
            popupCardView.heightAnchor.constraint(equalToConstant: selectedCellFrame.height),
        ]
        popupCardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(popupCardInitialConstraints)
        containerView.layoutIfNeeded()
        
        guard let windowRect = popupCardView.window?.bounds else { fatalError() }
        let isPadInterface = UIDevice.current.userInterfaceIdiom == .pad
        let windowWidth = windowRect.width
        let windowHeight = windowRect.height
        let horizontalInset: CGFloat = isPadInterface ? 10 :windowWidth / 40
        let verticalInset: CGFloat = isPadInterface ? (containerView.safeAreaInsets.top + 50) : windowHeight * 0.145
        
        let popupCardFinalConstraints = [
            popupCardView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: verticalInset),
            popupCardView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: horizontalInset),
            popupCardView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -horizontalInset),
            popupCardView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -verticalInset),
        ]
        
        
        
        
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
        
        self.presentationPropertyAnimator.addAnimations {
            fromVC.tabBar.frame.origin.y = screenSize.height
            naviCon.navigationBar.bounds.origin.y = naviCon.navigationBar.bounds.height + naviCon.view.safeAreaInsets.top
            naviCon.view.layoutIfNeeded()
        }
        
        self.presentationPropertyAnimator.addAnimations {
            NSLayoutConstraint.deactivate(popupCardInitialConstraints)
            NSLayoutConstraint.activate(popupCardFinalConstraints)
            
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
            
            popupCardView.memoTextViewLeadingConstraint.constant = 10
            popupCardView.memoTextViewTrailingConstraint.constant = -10
            popupCardView.memoTextView.bounds.origin.y = 0
            
            containerView.layoutIfNeeded()
        }
        
        self.presentationPropertyAnimator.addAnimations ({
            popupCardView.ellipsisButton.alpha = 1
        }, delayFactor: 0.1)
        
        self.presentationPropertyAnimator.addCompletion { animatingPosition in transitionContext.completeTransition(true) }
        
        self.presentationPropertyAnimator.startAnimation()
    }
    
    
    // MARK: - Present / Dismiss 구분선
    
    
    private func animationForDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let screenSize else { return }
        
        guard let popupCardVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? PopupCardViewController else { return }
        
        var selectedCell: TotalListCollectionViewCell
        
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
        
        self.disappearingPropertyAnimator.addAnimations {
            popupCardView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            popupCardView.alpha = 0
            popupCardView.layoutIfNeeded()
        }
        
        self.dismissalPropertyAnimatorForBars.addAnimations({
            naviCon.navigationBar.bounds.origin.y = 0
            tabBarCon.tabBar.frame.origin.y = screenSize.height - tabBarCon.tabBar.frame.height
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
        
        selectedCell = totalListVC.totalListCollectionView.cellForItem(at: popupCardVC.selectedIndexPath) as! TotalListCollectionViewCell
        
        selectedCell.heartImageView.image = popupCardVC.memoEntity.isFavorite ? UIImage(systemName: "heart.fill") : UIImage(systemName: "heart")
        popupCardView.selectedImageCollectionViewHeightConstraint.constant = popupCardView.numberOfImages == 0 ? 0 : 70
        
        selectedCell.alpha = 0
        convertedRect = selectedCell.convert(selectedCell.contentView.frame, to: totalListVC.totalListView)
        
        self.dismissalPropertyAnimator.addAnimations {
            popupCardView.translatesAutoresizingMaskIntoConstraints = true
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

            
            
            let shadowPathAnimation: CABasicAnimation = {
                
                let path = UIBezierPath(roundedRect: selectedCell.contentView.bounds, cornerRadius: 13)
                
                let animation = CABasicAnimation(keyPath: "shadowPath")
                animation.toValue = path.cgPath
                animation.timingFunction = CAMediaTimingFunction(controlPoints: 0.46, 1.32, 0.31, 1)
                animation.duration = 0.1
                animation.autoreverses = false
                animation.isRemovedOnCompletion = false
                animation.fillMode = .forwards
                return animation
            }()
            popupCardView.layer.add(shadowPathAnimation, forKey: "shadowPathAnimation")
            
            let shadowColorAnimation: CASpringAnimation = {
                let animation = CASpringAnimation(keyPath: "shadowColor")
                
                if popupCardView.traitCollection.userInterfaceStyle == .dark {
                    animation.toValue = UIColor.clear.cgColor
                } else {
                    animation.toValue = UIColor.currentTheme.cgColor
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

