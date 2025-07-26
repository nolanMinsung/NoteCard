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
    
    // IndexPath 두 개로 구분하는 경우는, dismiss중에 다른 셀을 또 탭 할 수도 있기 때문.
    private(set) var presentingIndexPath: IndexPath
    var restoringIndexPath: IndexPath? = nil
    private var startCellFrame: CGRect = .zero
    
    private var cardInset: NSDirectionalEdgeInsets
    
    // Snapshots
    var cellSnapshot: UIView? = nil
    var viewSnapshot: UIView? = nil
    
    let wispableCollectionView: WispableCollectionView
    
    init(
        wispableCollectionView: WispableCollectionView,
        selectedIndexPath: IndexPath,
        cardInset: NSDirectionalEdgeInsets,
        cellSnapshot: UIView? = nil
    ) {
        self.presentingIndexPath = selectedIndexPath
        self.wispableCollectionView = wispableCollectionView
        // 시작할 때 셀 frame
        guard let selectedCell = wispableCollectionView.cellForItem(at: selectedIndexPath) else { fatalError() }
        let convertedCellFrame = selectedCell.convert(selectedCell.contentView.frame, to: nil)
        self.startCellFrame = convertedCellFrame
        self.cardInset = cardInset
        self.cellSnapshot = cellSnapshot
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
    
    // MARK: - Presentation Animator (Interaction)
    func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return self.presentationInteractor
    }
    
}
