////
////  CardImageShowingInteractionController.swift
////  CardMemo
////
////  Created by 김민성 on 2023/11/02.
////
//
//import UIKit
//
//final class CardImageShowingInteractionController: UIPercentDrivenInteractiveTransition {
//    
//    var interactionInProgress: Bool = false
//    var shouldCompleteTransition: Bool = false
//    let cardImageShowingVC: CardImageShowingViewController
//    //lazy var cardImageShowingCollectionView = cardImageShowingVC.cardImageShowingCollectionView
//    
//    init(cardImageShowingVC: CardImageShowingViewController) {
//        self.cardImageShowingVC = cardImageShowingVC
//        super.init()
//        
//        self.prepareGestureRecognizer(in: self.cardImageShowingVC)
//    }
//    
//    private func prepareGestureRecognizer(in viewController: CardImageShowingViewController) {
//        
//        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
//        
//        viewController.cardImageShowingCollectionView.addGestureRecognizer(panGestureRecognizer)
//    }
//    
//    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
//        
//        guard let screenHeight = cardImageShowingVC.view.window?.windowScene?.screen.bounds.height else { return }
//        
//        var velocity = gesture.velocity(in: gesture.view)
//        let translation = gesture.translation(in: gesture.view)
//        var progress = translation.y / (screenHeight - 200)
//        
//        switch gesture.state {
//            
//        case .began:
//            self.interactionInProgress = true
//            self.cardImageShowingVC.dismiss(animated: true)
//            
//        case .changed:
//            self.update(progress)
//            self.shouldCompleteTransition = progress > 0.3 || velocity.y > 2000
//            print(velocity.y)
//            print(shouldCompleteTransition)
//        case .ended:
//            self.interactionInProgress = false
//            
//            switch self.shouldCompleteTransition {
//            case true:
//                self.finish()
//            case false:
//                self.cancel()
//            }
//            
//        case .cancelled:
//            self.interactionInProgress = false
//            switch self.shouldCompleteTransition {
//            case true:
//                self.finish()
//            case false:
//                self.cancel()
//            }
//            
//        default:
//            break
//        }
//        
//        
//        
//    }
//    
//    
//}
//
