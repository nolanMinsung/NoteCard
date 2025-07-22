//
//  CardTransitioningDelegate.swift
//  NoteCard
//
//  Created by 김민성 on 7/21/25.
//

import UIKit


final class CardTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    let presentationInteractor = UIPercentDrivenInteractiveTransition()
    let dismissInteractor = UIPercentDrivenInteractiveTransition()
    
    var isInteractivce: Bool = false
    
    var selectedIndexPath: IndexPath? = nil
    var startFrame: CGRect = .zero
    var endFrame: CGRect = .zero
    
    weak var presentingViewController: (any CardFrameRestorable)?
    
    init(presenting: any CardFrameRestorable) {
        self.presentingViewController = presenting
    }
    
    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        return CardPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        return CardPresentationAnimator(startFrame: startFrame, interactor: presentationInteractor)
    }
    
    func animationController(
        forDismissed dismissed: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        let dummyFrame = CGRect(x: 100, y: 300, width: 150, height: 225)
        guard let selectedIndexPath else {
            return CardDismissalAnimator(endFrame: dummyFrame)
        }
        let endFrame = presentingViewController?.getFrameOfSelectedCell(
            indexPath: selectedIndexPath
        ) ?? dummyFrame
        return CardDismissalAnimator(endFrame: endFrame)
    }
    
    func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
//        return self.isInteractivce ? self.presentationInteractor : nil
        return self.presentationInteractor
    }
    
    func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return self.isInteractivce ? self.dismissInteractor : nil
    }
    
    
}
