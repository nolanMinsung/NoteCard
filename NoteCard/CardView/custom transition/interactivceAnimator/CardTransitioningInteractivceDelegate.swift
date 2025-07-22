//
//  CardTransitioningInteractivceDelegate.swift
//  NoteCard
//
//  Created by 김민성 on 7/21/25.
//

import UIKit


final class CardTransitioningInteractivceDelegate: UIPercentDrivenInteractiveTransition {
    
    let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
    
    var endFrame: CGRect = .init(x: 100, y: 300, width: 150, height: 225)
    
    var hasStarted = false
    var shouldComplete = false // 트랜지션을 완료할지 여부
    
    // 이 인터랙터를 사용할 뷰 컨트롤러 (주로 presentedViewController)
    weak var viewController: UIViewController?
    
    // dismiss할 뷰 컨트롤러에 제스처 인식기를 연결
    func wireTo(viewController: UIViewController) {
        self.viewController = viewController
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        viewController.view.addGestureRecognizer(gesture)
    }
    
    override func startInteractiveTransition(_ transitionContext: any UIViewControllerContextTransitioning) {
        super.startInteractiveTransition(transitionContext)
        print(#function)
        
        let containerView = transitionContext.containerView
        let cardVC = transitionContext.viewController(forKey: .from) as! CardViewController
        let toVC = transitionContext.viewController(forKey: .to)
        containerView.layoutIfNeeded()
        animator.addAnimations {
            toVC?.view.transform = .identity
            toVC?.view.layer.cornerRadius = 0
            toVC?.view.clipsToBounds = false
        }
        print(#function)
        print("isInteractive: \(transitionContext.isInteractive)")
        cardVC.rootView.setCardDisappearingInitialState()
        animator.addAnimations { [weak self] in
            guard let self else { return }
            cardVC.rootView.setCardDisappearingFinalState(endFrame: self.endFrame)
        }
        
        animator.addCompletion { _ in
            transitionContext.completeTransition(true)
        }
        
        animator.startAnimation()
    }
    
    @objc func handleGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        print(#function)
        guard let view = gestureRecognizer.view else { return }
        
        // 제스처의 이동 거리 (예: 아래로 드래그하여 dismiss)
        let translation = gestureRecognizer.translation(in: view)
        
        // 화면 높이에 대한 진행률 계산
        // 여기서는 아래로 스와이프할 때 dismiss되도록, translation.y 값을 사용합니다.
        // 위로 스와이프라면 -translation.y 또는 다른 기준 사용
        let progress = translation.y / view.bounds.height
        switch gestureRecognizer.state {
        case .began:
            hasStarted = true
            // dismiss를 시작합니다.
            // 이때 UIKit은 transition delegate를 통해 interactionControllerForDismissal을 요청합니다.
            viewController?.dismiss(animated: true, completion: nil)
            print("----began----")
        case .changed:
            // 진행률 업데이트. 0.0 ~ 1.0 범위로 클램핑합니다.
            update(min(max(progress, 0.0), 1.0))
            
            // 일정 임계값 이상 진행되었는지 확인 (여기서는 50%)
            shouldComplete = progress > 0.5
            print("----changed----")
            print("updated value: \(min(max(progress, 0.0), 1.0))")
            print("progress: \(progress)")
            print("shouldComplete: \(shouldComplete)")
        case .ended:
            print("----ended----")
            print("shouldComplete: \(shouldComplete)")
            hasStarted = false
            // 제스처가 끝났을 때 완료할지 취소할지 결정
            if shouldComplete {
                finish() // 트랜지션 완료
            } else {
                cancel() // 트랜지션 취소 (원래 위치로 돌아감)
            }
            
        case .cancelled:
            print("----cancelled----")
            hasStarted = false
            cancel() // 제스처가 취소되었으므로 트랜지션도 취소
            
        default:
            break
        }
    }
    
    
    
}
