//
//  CardPresentationAnimator.swift
//  NoteCard
//
//  Created by 김민성 on 7/21/25.
//

import UIKit


final class CardPresentationAnimator: NSObject {
    
    let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
    
    // (10.0, 522.0, 145.0, 220.0)
    // (20.0, 1053.0, 145.0, 220.0)
//    var startFrame: CGRect = .init(x: 10, y: 522, width: 145, height: 220)
    var startFrame: CGRect = .init(x: 20, y: 1053, width: 145, height: 220)
    
    init(startFrame: CGRect) {
        self.startFrame = startFrame
    }
    
}
extension CardPresentationAnimator: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let fromVC = transitionContext.viewController(forKey: .from)
        let cardVC = transitionContext.viewController(forKey: .to) as! CardViewController
        let cardView = cardVC.rootView
        containerView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: containerView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        containerView.layoutIfNeeded()
        animator.addAnimations {
            fromVC?.view.transform = .init(scaleX: 0.95, y: 0.95)
            fromVC?.view.layer.cornerRadius = 20
            fromVC?.view.clipsToBounds = true
        }
        animator.startAnimation()
        cardVC.rootView.animateCardShowing(startFrame: startFrame) { isFinished in
            transitionContext.completeTransition(isFinished)
        }
    }
    
}
