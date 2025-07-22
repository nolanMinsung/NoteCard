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
        dragPanGesture.state = .cancelled
        dismiss(animated: true)
    }
    
    @objc private func dragPanGesturehandler(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        /// pan gesture의 시작점으로부터의 거리.
        let hypotenuse = sqrt(pow(translation.x, 2) + pow(translation.y,2))
        let scale = max(0.8, 1 - (abs(hypotenuse)/1000))
        
        let translationTransform = CGAffineTransform(translationX: translation.x, y: translation.y)
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
        
        switch sender.state {
        case .began:
            break
        case .changed:
            rootView.card.transform = scaleTransform.concatenating(translationTransform)
        default:
            if hypotenuse < 100 {
                UIView.springAnimate(withDuration: 0.5, options: .allowUserInteraction) { [weak self] in
                    self?.rootView.card.transform = .identity
                }
            } else {
                sender.cancelsTouchesInView = true
                dismiss(animated: true)
            }
        }
    }
    
}
