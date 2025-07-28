//
//  WispPresentationController.swift
//  NoteCard
//
//  Created by 김민성 on 7/21/25.
//

import UIKit

internal class WispPresentationController: UIPresentationController {
    
    override init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
    }
    
    override func presentationTransitionWillBegin() { }
    
    override func presentationTransitionDidEnd(_ completed: Bool) { }
    
    override func dismissalTransitionWillBegin() { }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        print(#function)
    }
    
}
