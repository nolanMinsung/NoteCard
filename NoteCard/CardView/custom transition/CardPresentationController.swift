//
//  CardPresentationController.swift
//  NoteCard
//
//  Created by 김민성 on 7/21/25.
//

import UIKit

class CardPresentationController: UIPresentationController {
    
    let cardVC: CardViewController
    
    override init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        guard let cardVC = presentedViewController as? CardViewController else { fatalError() }
        self.cardVC = cardVC
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }
    
    override func presentationTransitionWillBegin() {
        print(#function)
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        print(#function)
    }
    
    override func dismissalTransitionWillBegin() {
        print(#function)
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        print(#function)
    }
    
}
