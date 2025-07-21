//
//  CardDismissalAnimator.swift
//  NoteCard
//
//  Created by 김민성 on 7/21/25.
//

import UIKit


final class CardDismissalAnimator: NSObject {
    
    let animator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1)
    
    var endFrame: CGRect = .init(x: 100, y: 300, width: 150, height: 225)
    
    init(endFrame: CGRect) {
        self.endFrame = endFrame
    }
    
}


extension CardDismissalAnimator: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        0.5
    }
    
    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let cardVC = transitionContext.viewController(forKey: .from) as! CardViewController
        let toVC = transitionContext.viewController(forKey: .to)
        containerView.layoutIfNeeded()
        animator.addAnimations {
            toVC?.view.transform = .identity
            toVC?.view.layer.cornerRadius = 0
            toVC?.view.clipsToBounds = false
        }
        animator.startAnimation()
        cardVC.rootView.animateCardDisappearing(endFrame: endFrame) { isFinished in
            transitionContext.completeTransition(isFinished)
        }
    }
    
    
}
