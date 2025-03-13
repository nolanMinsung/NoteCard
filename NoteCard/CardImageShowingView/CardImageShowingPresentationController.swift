//
//  CardImageShowingPresentationController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class CardImageShowingPresentationController: UIPresentationController {
    
    let blurView: UIVisualEffectView = {
        //let view = UIVisualEffectView(effect: blurEffect)
        let view = UIVisualEffectView()
        view.alpha = 1.0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override var shouldRemovePresentersView: Bool {
        return false
    }
    
    
    override func presentationTransitionWillBegin() {
        
        guard let containerView else { return }
        containerView.addSubview(self.blurView)
        
        self.blurView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0).isActive = true
        self.blurView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0).isActive = true
        self.blurView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0).isActive = true
        self.blurView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0).isActive = true
        
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] coordinatorContext in
            guard let self else { return }
            //self.blurView.alpha = 1.0
            self.blurView.effect = UIBlurEffect(style: UIBlurEffect.Style.systemMaterial)
        })
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
    }
    
    
    
    
    
    override func dismissalTransitionWillBegin() {
//        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] coordinatorContext in
//            guard let self else { return }
//            self.blurView.effect = .none
//        })
        self.blurView.effect = .none
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        switch completed {
        case true:
            self.blurView.removeFromSuperview()
        case false:
            return
        }
    }
    
    
}

