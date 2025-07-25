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
    lazy var dynamicAnimator = UIDynamicAnimator(referenceView: rootView)
    
    let tapGesture = UITapGestureRecognizer()
    let dragPanGesture = UIPanGestureRecognizer()
    
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
    
    /*
     https://developer.apple.com/documentation/UIKit/handling-key-presses-made-on-a-physical-keyboard#Detect-a-key-press
     */
    // Handle someone pressing a key on a physical keyboard.
    override func pressesBegan(_ presses: Set<UIPress>,
                               with event: UIPressesEvent?) {
        
        var didHandleEvent = false
        
        for press in presses {
            
            // Get the pressed key.
            guard let key = press.key else { continue }
            
            if key.charactersIgnoringModifiers == UIKeyCommand.inputEscape {
                // Someone pressed the escape key.
                // Respond to the key-press event.
                didHandleEvent = true
                dismissCard()
            }
        }
        
        if didHandleEvent == false {
            // If someone presses a key that you're not handling,
            // pass the event to the next responder.
            super.pressesBegan(presses, with: event)
        }
    }
    
}


extension CardViewController {
    
    private func setupGestures() {
        tapGesture.addTarget(self, action: #selector(backgroundBlurTapped))
        dragPanGesture.addTarget(self, action: #selector(dragPanGesturehandler))
        dragPanGesture.allowedScrollTypesMask = [.continuous]
        
        rootView.backgroundBlurView.addGestureRecognizer(tapGesture)
        rootView.card.addGestureRecognizer(dragPanGesture)
    }
    
    @objc private func backgroundBlurTapped(_ sender: UITapGestureRecognizer) {
        dismissCard()
    }
    
    @objc private func dragPanGesturehandler(_ gesture: UIPanGestureRecognizer) {
        // 직전 제스처의 위치로부터 이동 거리(매 change state 호출 시마다 위치 재정렬함.)
        let translation = gesture.translation(in: view)
        /// pan gesture의 시작점으로부터의 거리.
        let hypotenuse = sqrt(pow(translation.x, 2) + pow(translation.y,2))
//        let scaleValue = 1 - ((translation.y/1000) + (abs(translation.x)/1000))
        let curve = UIDevice.current.userInterfaceIdiom == .phone ? 100.0 : 300.0
        let scaleValue = 1.0 + 0.3 * (exp(-(abs(translation.x)/400.0 + translation.y/100.0)) - 1.0)
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
//            print(cardCenterDiff)
//            print(hypotenuse)
//
//            rootView.card.center.x += translation.x
//            rootView.card.center.y += translation.y
//            rootView.card.transform = scaleTransform
//            gesture.setTranslation(.zero, in: view)
            
        default:
            let velocity = gesture.velocity(in: view)
            let velocityScalar = sqrt(pow(velocity.x, 2) + pow(velocity.y, 2))
            let shouldDismiss = ((hypotenuse > 130 || velocityScalar > 1000) &&
                                 (translation.y > abs(translation.x)/2))
            
            if shouldDismiss {
//                let itemBehavior = UIDynamicItemBehavior(items: [rootView.card])
//                itemBehavior.addLinearVelocity(velocity, for: rootView.card)
//                itemBehavior.resistance = 10.0
//                dynamicAnimator.addBehavior(itemBehavior)
                dismissCard()
            } else {
                UIView.springAnimate(withDuration: 0.5, options: .allowUserInteraction) { [weak self] in
                    guard let self else { return }
                    self.rootView.card.transform = .identity
                    self.rootView.card.translatesAutoresizingMaskIntoConstraints = false
                    self.rootView.layoutIfNeeded()
                }
            }
        }
    }
    
    
    private func dismissCard() {
        print(#function)
        guard let transitioningDelegate = transitioningDelegate as? CardTransitioningDelegate else { return }
        guard let cardFrameRestorable = transitioningDelegate.presentingViewController else { fatalError() }
        
        dragPanGesture.state = .cancelled
        transitioningDelegate.presentationInteractor.pause()
        transitioningDelegate.restoringIndexPath = transitioningDelegate.presentingIndexPath
        transitioningDelegate.viewSnapshot = rootView.card.snapshotView(afterScreenUpdates: false)
        cardFrameRestorable.restore(
            // 이것때문에 카드 나타나는 중간에 배경 빠르게 탭 해서 dismiss하면 순간적으로 커졌다 작아지는 현상 생김.
            // 근데 이 시점에 card는 이미 layout이 잡힌 상태라서 startFrame에 들어가는 rootView.card.frame은
            // 어쩔 수 없이 정상적인 present가 됐을 때의 card의 frame이 된다..
            startFrame: rootView.card.frame,
            indexPath: transitioningDelegate.restoringIndexPath!
        )
        dismiss(animated: false)
//        transitioningDelegate.presentationInteractor.update(0)
//        transitioningDelegate.presentationInteractor.cancel()
        rootView.card.alpha = 0
        rootView.isHidden = true
    }
    
}
