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
    
    var collectionView: UICollectionView
    var presentingIndexPath: IndexPath
    var restoringIndexPath: IndexPath? = nil
    var startFrame: CGRect = .zero
    var endFrame: CGRect = .zero
    
    var cellSnapshot: UIView? = nil
    var viewSnapshot: UIView? = nil
    
    weak var presentingViewController: (any CardFrameRestorable)?
    
    init(
        presenting: any CardFrameRestorable,
        collectionView: UICollectionView,
        selectedIndexPath: IndexPath,
        startFrame: CGRect,
        cellSnapshot: UIView? = nil
    ) {
        print("transitioning Delegate 생성됨")
        self.presentingViewController = presenting
        self.collectionView = collectionView
        self.presentingIndexPath = selectedIndexPath
        self.startFrame = startFrame
        self.cellSnapshot = cellSnapshot
    }
    
    deinit {
        print("transitioning Delegate 사라짐")
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
        let endFrame = presentingViewController?.getFrameOfSelectedCell(
            indexPath: presentingIndexPath
        ) ?? dummyFrame
        return CardDismissalAnimator(endFrame: endFrame)
    }
    
    func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return self.presentationInteractor
    }
    
    func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return self.isInteractivce ? self.dismissInteractor : nil
    }
    
    
}
