//
//  CardTransitioningInteractivceDelegate.swift
//  NoteCard
//
//  Created by 김민성 on 7/21/25.
//

import UIKit


final class CardTransitioningInteractivceDelegate: UIPercentDrivenInteractiveTransition,
                                                    UIViewControllerAnimatedTransitioning {
    
    
    let animator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1)
    
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        
    }
    
    override func cancel() {
        super.cancel()
        
        
    }
    
    
}
