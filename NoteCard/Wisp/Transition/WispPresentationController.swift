//
//  WispPresentationController.swift
//  NoteCard
//
//  Created by 김민성 on 7/21/25.
//

import UIKit

class WispPresentationController: UIPresentationController {
    
    let cardVC: WispViewController
    
    override init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        guard let cardVC = presentedViewController as? WispViewController else { fatalError() }
        self.cardVC = cardVC
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
