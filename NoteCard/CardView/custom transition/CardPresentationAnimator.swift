//
//  CardPresentationAnimator.swift
//  NoteCard
//
//  Created by 김민성 on 7/21/25.
//

import UIKit


final class CardPresentationAnimator: NSObject {
    
    // (10.0, 522.0, 145.0, 220.0)
    // (20.0, 1053.0, 145.0, 220.0)
//    var startFrame: CGRect = .init(x: 10, y: 522, width: 145, height: 220)
    var startFrame: CGRect = .init(x: 20, y: 1053, width: 145, height: 220)
    
    let interactor: UIPercentDrivenInteractiveTransition
    
    init(startFrame: CGRect, interactor: UIPercentDrivenInteractiveTransition) {
        self.startFrame = startFrame
        self.interactor = interactor
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
        cardVC.rootView.setCardShowingInitialState(startFrame: startFrame)
        cardVC.rootView.backgroundBlurView.setBlurFromZero(intensity: 0.1, animated: true)
        
        let homeViewBackgroundColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .light {
                return UIColor.systemGray6
            } else {
                return UIColor.black
            }
        }
        fromVC?.view.window?.backgroundColor = homeViewBackgroundColor
        
        
        /// - Important: Interactivce한 트랜지션을 위해서는 UIView.animate를 사용해야 함.
        /// UIViewPropertyAnimator를 사용하면 interactive한 애니메이션이 제대로 동작하지 않음 주의.
        UIView.springAnimate(
            withDuration: transitionDuration(using: transitionContext),
            options: .allowUserInteraction,
            animations: {
                fromVC?.view.transform = .init(scaleX: 0.95, y: 0.95)
                cardVC.rootView.setCardShowingFinalState()
            },
            completion: { _ in transitionContext.completeTransition(!transitionContext.transitionWasCancelled) }
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.interactor.finish()
        }
        
    }
    
}
