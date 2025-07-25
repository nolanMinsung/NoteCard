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
    
    // IndexPath 두 개로 구분하는 경우는, dismiss중에 다른 셀을 또 탭 할 수도 있기 때문.
    var presentingIndexPath: IndexPath
    var restoringIndexPath: IndexPath? = nil
    var startCellFrame: CGRect = .zero
//    var endFrame: CGRect = .zero
    
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
        // 시작할 때 셀 frame
        self.startCellFrame = startFrame
        self.cellSnapshot = cellSnapshot
    }
    
    deinit {
        print("transitioning Delegate 사라짐")
    }
    
    // MARK: - Presentation Controller
    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        return CardPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    
    // MARK: - Presentation Animator
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        return CardPresentationAnimator(startFrame: startCellFrame, interactor: presentationInteractor)
    }
    
//    func animationController(
//        forDismissed dismissed: UIViewController
//    ) -> (any UIViewControllerAnimatedTransitioning)? {
//        let dummyFrame = CGRect(x: 100, y: 300, width: 150, height: 225)
//        let endFrame = presentingViewController?.getFrameOfSelectedCell(
//            indexPath: presentingIndexPath
//        ) ?? dummyFrame
//        return CardDismissalAnimator(endFrame: endFrame)
//    }
    
    // MARK: - Presentation Animator (Interaction)
    func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return self.presentationInteractor
    }
    
    
    // MARK: - Dismissal Animator (Interaction)
    func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return self.isInteractivce ? self.dismissInteractor : nil
    }
    
    
}
