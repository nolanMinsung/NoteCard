//
//  WispPresenter.swift
//  NoteCard
//
//  Created by 김민성 on 7/28/25.
//

import UIKit


public final class WispPresenter {
    
    private weak var collectionView: WispableCollectionView?

    init(collectionView: WispableCollectionView) {
        self.collectionView = collectionView
    }
    
    @MainActor func present(
        _ viewControllerToPresent: any WispDismissable,
        from indexPath: IndexPath,
        in presentingViewController: UIViewController,
        configuration: WispConfiguration = .default
    ) {
        let selectedCell = collectionView?.cellForItem(at: indexPath)
        let cellSnapshot = selectedCell?.snapshotView(afterScreenUpdates: false)
        selectedCell?.alpha = 0
        
        let wispContext = WispContext(
            collectionView: collectionView,
            indexPath: indexPath,
            sourceCellSnapshot: cellSnapshot,
            presentedSnapshot: nil,
            sourceViewController: presentingViewController,
            configuration: .default
        )
        let wispTransitioningDelegate = WispTransitioningDelegate(context: wispContext)
        
        WispManager.shared.activeContext = wispContext
        viewControllerToPresent.modalPresentationStyle = .custom
        viewControllerToPresent.transitioningDelegate = wispTransitioningDelegate
        presentingViewController.present(viewControllerToPresent, animated: true)
    }
    
}
