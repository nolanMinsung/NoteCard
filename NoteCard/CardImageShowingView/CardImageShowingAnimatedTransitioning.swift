//
//  CardImageShowingDismissalAnimatedTransitioning.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit


class CardImageShowingAnimatedTransitioning: NSObject {
    
    
    let interactionController: UIPercentDrivenInteractiveTransition?
    
    var animationType: AnimationType
    
    
    init(animationType: AnimationType, interactionController: UIPercentDrivenInteractiveTransition? = nil) {
        self.animationType = animationType
        self.interactionController = interactionController
    }
    
    
    
    
    
    
}


extension CardImageShowingAnimatedTransitioning: UIViewControllerAnimatedTransitioning {
    
    
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 2
    }
    
    
    
//    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
//        
//        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? CardImageShowingViewController else { return UIViewPropertyAnimator() }
//        
//        guard let screenHeight = fromVC.view.window?.windowScene?.screen.bounds.height else { return UIViewPropertyAnimator() }
//        
//        let animator = UIViewPropertyAnimator(duration: 0.5, curve: UIView.AnimationCurve.easeInOut)
//        animator.addAnimations {
//            fromVC.view.frame.origin.y = screenHeight - 200
//        }
//        animator.addCompletion { _ in
//            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
//        }
//        
//        return animator
//    }
    
    
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch self.animationType {
        case .present:
            self.animationForPresentation(using: transitionContext)
        case .dismiss:
            self.animationForDismissal(using: transitionContext)
        }
    }
    
    
    
    private func animationForPresentation(using transitionContext: UIViewControllerContextTransitioning) {
        print(#function)
        
        
        guard let screenSize = UIScreen.current?.bounds.size else { fatalError() }
        guard let cardImageShowingVC = transitionContext.viewController(forKey: .to) as? CardImageShowingViewController else { fatalError() }
        guard let cardImageShowingView = cardImageShowingVC.view as? CardImageShowingView else { fatalError() }
        let cardImageShowingCollectionView = cardImageShowingView.cardImageShowingCollectionView
        let dismissButton = cardImageShowingView.dismissButton
        
        transitionContext.containerView.addSubview(cardImageShowingView)
        cardImageShowingView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: screenSize)
        
        cardImageShowingCollectionView.frame.origin.y = screenSize.height * 0.6
//        cardImageShowingCollectionView.alpha = 0
        
        dismissButton.alpha = 0.0
        dismissButton.transform = CGAffineTransform(scaleX: 0.05, y: 0.05)
        
        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
        
        animator.addAnimations {
            cardImageShowingCollectionView.frame.origin.y = 0
            dismissButton.transform = CGAffineTransform.identity
        }
        
        animator.addAnimations({
//            cardImageShowingCollectionView.alpha = 1
        }, delayFactor: 0.2)
        
        animator.addAnimations({
            dismissButton.alpha = 0.7
        }, delayFactor: 0.3)
        
        animator.addCompletion { position in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        animator.startAnimation()
        
        
    }
    
    
    
    
    
    
//---------------------------------------------------------------------------------------------------------------
    
    
    
    
    
    
    private func animationForDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        print(#function)
        
        guard let screenSize = UIScreen.current?.bounds.size else { fatalError() }
        guard let cardImageShowingVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? CardImageShowingViewController else { return }
        guard let cardImageShowingView = cardImageShowingVC.view as? CardImageShowingView else { fatalError() }
        
        let cardImageShowingCollectionView = cardImageShowingView.cardImageShowingCollectionView
        let blurView = cardImageShowingView.blurView
        let dismissButton = cardImageShowingVC.dismissButton
        
        cardImageShowingCollectionView.alpha = 1
        
        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
        let buttonAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
        
//        blurView.effect = UIBlurEffect(style: .systemMaterial)
        
        animator.addAnimations {
            blurView.frame.origin.y = screenSize.height * 1.0
            
            cardImageShowingCollectionView.frame.origin.y = screenSize.height * 1.0
//            cardImageShowingCollectionView.alpha = 0
            
            cardImageShowingView.layoutSubviews()
        }
        
        animator.addAnimations({
            blurView.alpha = 0
        }, delayFactor: 0.5)
        
        buttonAnimator.addAnimations {
            dismissButton.transform = CGAffineTransform(scaleX: 0.05, y: 0.05)
            dismissButton.alpha = 0
        }
        
        
        animator.addCompletion { _ in
//            blurView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        animator.startAnimation()
        buttonAnimator.startAnimation()
    }
    
    
    
}

