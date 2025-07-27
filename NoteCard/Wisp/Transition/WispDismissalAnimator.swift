//
//  WispDismissalAnimator.swift
//  NoteCard
//
//  Created by 김민성 on 7/21/25.
//

import UIKit


final class WispDismissalAnimator: NSObject {
    
    var endFrame: CGRect = .init(x: 100, y: 300, width: 150, height: 225)
    
    init(endFrame: CGRect) {
        self.endFrame = endFrame
    }
    
}


extension WispDismissalAnimator: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        0.4
    }
    
    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let cardVC = transitionContext.viewController(forKey: .from) as! WispViewController
        let toVC = transitionContext.viewController(forKey: .to)
        containerView.layoutIfNeeded()
        
        containerView.isUserInteractionEnabled = false
        cardVC.rootView.isUserInteractionEnabled = false
        
        /// - Important: Interactivce한 트랜지션을 위해서는 UIView.animate를 사용해야 함.
        /// UIViewPropertyAnimator를 사용하면 interactive한 애니메이션이 제대로 동작하지 않음 주의.
        UIView.springAnimate(
            withDuration: transitionDuration(using: transitionContext),
            options: .allowUserInteraction
        ) { [weak self] in
            guard let self else { return }
            cardVC.rootView.setCardDisappearingFinalState(endFrame: self.endFrame)
            cardVC.rootView.backgroundBlurView.removeBlur(animated: true)
        } completion: { _ in
            transitionContext.completeTransition(true)
        }
        
    }
    
    
}
