//
//  WispDismissable.swift
//  NoteCard
//
//  Created by 김민성 on 7/28/25.
//

import UIKit


protocol WispDismissable: UIViewController {
    
    var viewInset: NSDirectionalEdgeInsets { get }
    
    func dismissCard()
    
}



extension WispDismissable {
    
    func dragPanGesturehandler(_ gesture: UIPanGestureRecognizer) {
        // 직전 제스처의 위치로부터 이동 거리(매 change state 호출 시마다 위치 재정렬함.)
        let translation = gesture.translation(in: view)
        /// pan gesture의 시작점으로부터의 거리.
        let hypotenuse = sqrt(pow(translation.x, 2) + pow(translation.y,2))
        let scaleValue = 1.0 + 0.3 * (exp(-(abs(translation.x)/400.0 + translation.y/100.0)) - 1.0)
        let scale = min(1.05, max(0.7, scaleValue))
        
        let yPosition = translation.y < 0 ? translation.y / 3 : translation.y
        let translationTransform = CGAffineTransform(translationX: translation.x, y: yPosition)
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
        
        switch gesture.state {
        case .began:
            break
        case .changed:
            view.transform = scaleTransform.concatenating(translationTransform)
        default:
            let velocity = gesture.velocity(in: view)
            let velocityScalar = sqrt(pow(velocity.x, 2) + pow(velocity.y, 2))
            let shouldDismiss = (hypotenuse > 130 || velocityScalar > 1000) && (translation.y > 0)
            
            if shouldDismiss {
                dismissCard()
            } else {
                UIView.springAnimate(withDuration: 0.5, options: .allowUserInteraction) { [weak self] in
                    guard let self else { return }
                    self.view.transform = .identity
                    self.view.translatesAutoresizingMaskIntoConstraints = false
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
    
    @MainActor
    func dismissCard() {
        let screenCornerRadius = UIDevice.current.userInterfaceIdiom == .pad ? 32.0 : 37.0
        view.layer.cornerRadius = screenCornerRadius
        view.layer.cornerCurve = .continuous
        
        WispManager.shared.handleInteractiveDismissEnded(startFrame: view.frame)
        dismiss(animated: false)
        view.alpha = 0
        view.isHidden = true
    }
    
    func setViewShowingInitialState(startFrame: CGRect) {
        let cardFinalFrame = view.frame
        
        let centerDiffX = startFrame.center.x - cardFinalFrame.center.x
        let centerDiffY = startFrame.center.y - cardFinalFrame.center.y
        
        let cardWidthScaleDiff = startFrame.width / cardFinalFrame.width
        let cardHeightScaleDiff = startFrame.height / cardFinalFrame.height
        
        let scaleTransform = CGAffineTransform(scaleX: cardWidthScaleDiff, y: cardHeightScaleDiff)
        let centerTransform = CGAffineTransform(translationX: centerDiffX, y: centerDiffY)
        let cardTransform = scaleTransform.concatenating(centerTransform)
        let screenCornerRadius = UIDevice.current.userInterfaceIdiom == .pad ? 32.0 : 37.0
        view.layer.cornerRadius = screenCornerRadius / ((cardWidthScaleDiff + cardHeightScaleDiff)/2)
        view.layer.cornerCurve = .continuous
        view.transform = cardTransform
    }
    
    func setViewShowingFinalState() {
        let screenCornerRadius = UIDevice.current.userInterfaceIdiom == .pad ? 32.0 : 37.0
        view.layer.cornerRadius = screenCornerRadius
        view.layer.cornerCurve = .continuous
        view.transform = .identity
    }
    
}
