//
//  CardViewController.swift
//  NoteCard
//
//  Created by 김민성 on 7/21/25.
//

import UIKit

class CardViewController: UIViewController {
    
    let memoEntity: MemoEntity
    
    let rootView = CardView()
    
    lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundBlurTapped))
    lazy var dragPanGesture = UIPanGestureRecognizer(target: self, action: #selector(dragPanGesturehandler))
    
    init(memoEntity: MemoEntity) {
        self.memoEntity = memoEntity
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = rootView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rootView.configure(with: memoEntity)
        setupGestures()
    }
    
}


extension CardViewController {
    
    private func setupGestures() {
        rootView.backgroundBlurView.addGestureRecognizer(tapGesture)
        rootView.card.addGestureRecognizer(dragPanGesture)
    }
    
    @objc private func backgroundBlurTapped(_ sender: UITapGestureRecognizer) {
        guard let transitioningDelegate = transitioningDelegate as? CardTransitioningDelegate else { return }
        transitioningDelegate.presentationInteractor.cancel()
        transitioningDelegate.viewSnapshot = rootView.card.snapshotView(afterScreenUpdates: false)
        dragPanGesture.state = .cancelled
        guard let cardFrameRestorable = transitioningDelegate.presentingViewController else {
            fatalError()
        }
        transitioningDelegate.restoringIndexPath = transitioningDelegate.presentingIndexPath
        cardFrameRestorable.restore(
            startFrame: rootView.card.frame,
            indexPath: transitioningDelegate.restoringIndexPath!
        )
//        dismiss(animated: true)
        dismiss(animated: false)
    }
    
    @objc private func dragPanGesturehandler(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        /// pan gesture의 시작점으로부터의 거리.
        let hypotenuse = sqrt(pow(translation.x, 2) + pow(translation.y,2))
//        let scaleValue = 1 - ((translation.y/1000) + (abs(translation.x)/1000))
        let curve = UIDevice.current.userInterfaceIdiom == .phone ? 100.0 : 300.0
        let scaleValue = 1.0 + 0.3 * (exp(-(abs(translation.x) + translation.y)/300.0) - 1)
        let scale = min(1.05, max(0.7, scaleValue))
        
        let yPosition = translation.y < 0 ? translation.y / 3 : translation.y
        let translationTransform = CGAffineTransform(translationX: translation.x, y: yPosition)
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
        
        switch gesture.state {
        case .began:
            // targetCell 숨기기
            guard let transitioningDelegate = transitioningDelegate as? CardTransitioningDelegate else { return }
            transitioningDelegate.restoringIndexPath = transitioningDelegate.presentingIndexPath
            break
        case .changed:
            rootView.card.transform = scaleTransform.concatenating(translationTransform)
            
        default:
            let velocity = gesture.velocity(in: view)
            let velocityScalar = sqrt(pow(velocity.x, 2) + pow(velocity.y, 2))
            
            let shouldDismiss = (hypotenuse > 130 || velocityScalar > 1000)
            if shouldDismiss {
                guard let transitioningDelegate = transitioningDelegate as? CardTransitioningDelegate else { return }
                guard let restorableVC = transitioningDelegate.presentingViewController else {
                    fatalError()
                }
                dismiss(animated: false)
                transitioningDelegate.viewSnapshot = rootView.card.snapshotView(afterScreenUpdates: false)
                transitioningDelegate.restoringIndexPath = transitioningDelegate.presentingIndexPath
                restorableVC.restore(
                    startFrame: rootView.card.frame,
                    indexPath: transitioningDelegate.restoringIndexPath!
                )
            } else {
                UIView.springAnimate(withDuration: 0.5, options: .allowUserInteraction) { [weak self] in
                    self?.rootView.card.transform = .identity
                }
            }
        }
    }
    
}
