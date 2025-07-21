//
//  CardTransitioningDelegate.swift
//  NoteCard
//
//  Created by 김민성 on 7/21/25.
//

import UIKit


final class CardTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
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
        return CardPresentationAnimator(startFrame: startFrame)
    }
    
    func animationController(
        forDismissed dismissed: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        let dummyFrame = CGRect(x: 100, y: 300, width: 150, height: 225)
        guard let selectedIndexPath else {
            return CardDismissalAnimator(endFrame: dummyFrame)
        }
        let endFrame = presentingViewController?.getFrameOfCell(
            indexPath: selectedIndexPath
        ) ?? dummyFrame
        return CardDismissalAnimator(endFrame: endFrame)
    }
    
}
