//
//  PercentDrivenInteractiveTransition.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

//레이웬더리치 강의에서 SwipeInteractionController에 해당
class PercentDrivenInteractiveTransition: UIPercentDrivenInteractiveTransition {
    
    var interactionInProgress = false
    
    private var shouldCompleteTransition = false
    
    private weak var viewController: UIViewController!
    
    
    
    init(viewController: UIViewController) {
        super.init()
        self.viewController = viewController
        self.prepareGestureRecognizer(in: viewController.view)
    }
    
    
    private func prepareGestureRecognizer(in view: UIView) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        //let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        //gesture.edges = UIRectEdge.left
        
//        view.addGestureRecognizer(panGesture)
        //view.addGestureRecognizer(gesture)
    }
    
    
    @objc func handleGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view!.superview!)
        var progress = (translation.x / 200)
        progress = fmax(progress, 0.0)
        progress = fmin(progress, 1.0)
        
        switch gestureRecognizer.state {
        case .began:
            self.interactionInProgress = true
            self.viewController.dismiss(animated: true, completion: nil)
        case .changed:
            self.shouldCompleteTransition = progress > 0.5
            update(progress)
        case .cancelled:
            self.interactionInProgress = false
            self.cancel()
        case .ended:
            self.interactionInProgress = false
            if self.shouldCompleteTransition {
                self.finish()
            } else {
                self.cancel()
            }
        default:
            break
        }
    }
    
    
    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        
//        let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view)
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view!)
        var progress = (translation.y / 200)
        progress = fmax(progress, 0.0)
        progress = fmin(progress, 1.0)
        
        switch gestureRecognizer.state {
        case .began:
            self.interactionInProgress = true
            self.viewController.dismiss(animated: true, completion: nil)
        case .changed:
            self.shouldCompleteTransition = progress > 0.5
            update(progress)
        case .cancelled:
            self.interactionInProgress = false
            self.cancel()
        case .ended:
            self.interactionInProgress = false
            if self.shouldCompleteTransition {
                self.finish()
            } else {
                self.cancel()
            }
        default:
            break
        }
    }
}

