//
//  WispTransitioningDelegate.swift
//  NoteCard
//
//  Created by 김민성 on 7/21/25.
//

import Combine
import UIKit


internal final class WispTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    let presentationInteractor = UIPercentDrivenInteractiveTransition()
    private var startCellFrame: CGRect = .zero
    private var cancellables: Set<AnyCancellable> = []
    
    init(context: WispContext) {
        super.init()
        // 시작할 때 셀 frame
        guard let selectedCell = context.collectionView?.cellForItem(at: context.indexPath) else { fatalError() }
        let convertedCellFrame = selectedCell.convert(selectedCell.contentView.frame, to: nil)
        self.startCellFrame = convertedCellFrame
    }
    
    // MARK: - Presentation Controller
    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        return WispPresentationController(
            presentedViewController: presented,
            presenting: presenting,
        )
    }
    
    // MARK: - Presentation Animator
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        return WispCardPresentationAnimator(startFrame: startCellFrame, interactor: presentationInteractor)
    }
    
    // MARK: - Presentation Animator (Interaction)
    func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return self.presentationInteractor
    }
    
}
