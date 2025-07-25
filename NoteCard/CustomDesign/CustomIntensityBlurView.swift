//
//  CustomIntensityBlurView.swift
//  NoteCard
//
//  Created by 김민성 on 7/25/25.
//

import UIKit



// curve는 항상 linear
// animator를 갈아끼우는 식으로 구현?
class CustomIntensityBlurView: UIView {
    
    //MARK: - Properties
    
    private(set) var currentIntensity: Double
    
    private let blurView = UIVisualEffectView(effect: nil)
    
    private var blurStyle: UIBlurEffect.Style = .regular
    
    private var animator: UIViewPropertyAnimator? = nil {
        willSet {
            animator?.stopAnimation(true)
            animator?.finishAnimation(at: .current)
        }
        didSet {
            animator?.pausesOnCompletion = true
        }
    }
    
    //MARK: - Life Cycle
    
    /// 원하는 세기의 블러를 적용한 UIVisualEffectView 생성
    /// - Parameters:
    ///   - style: blur의 style. UIBlurEffect.Style 타입
    ///   - intensity: 적용할 블러의 세기 0에서 1 사이의 값을 가지며 0은 블러 전혀 없음, 1은 UIKit의 기본 블러 세기를 의미
    ///   - animationDuration: 애니메이션 적용할 시간. 기본값 0.5
    init(blurStyle style: UIBlurEffect.Style, intensity: CGFloat) {
        self.currentIntensity = intensity
        self.blurStyle = style
        super.init(frame: .zero)
        
        addSubview(blurView)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        let edges = [
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ]
        NSLayoutConstraint.activate(edges)
        
        animator = UIViewPropertyAnimator(duration: 1.0, curve: .linear)
        animator?.pausesOnCompletion = true
        animator?.addAnimations { [weak self] in
            self?.blurView.effect = UIBlurEffect(style: style)
        }
        animator?.fractionComplete = intensity
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    
    deinit {
        animator?.stopAnimation(true)
        animator?.finishAnimation(at: .current)
    }
    
    
    // 무조건 블러 없음 -> 커스텀 강도 블러 식으로 애니메이션이 진행됨.
    func setBlurFromZero(intensity: Double, animated: Bool, duration: TimeInterval = 0.5) {
        // DispatchQueue.main.async { } 블럭 안에 감싸지 않으면
        // 다른 애니메이션 블럭 안에서 호출했을 때 의도한 바와 다르게 동작하는 듯 함..
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let intensity = max(0, min(intensity, 1))
            let totalDuration = duration / intensity
            
            blurView.effect = nil
            animator = UIViewPropertyAnimator(duration: totalDuration, curve: .linear)
            animator?.addAnimations {[weak self] in
                guard let self else { return }
                self.blurView.effect = UIBlurEffect(style: self.blurStyle)
            }
            
            if animated {
                animator?.startAnimation()
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                    self?.animator?.pauseAnimation()
                }
            } else {
                animator?.fractionComplete = intensity
            }
        }
    }
    
    func removeBlur(animated: Bool, duration: TimeInterval = 0.5) {
        if animated {
            UIView.animate(withDuration: duration) { [weak self] in
                self?.blurView.effect = nil
            }
        } else {
            blurView.effect = nil
        }
    }
    
}

extension CustomIntensityBlurView {
    
    //MARK: - Func
    
    func applyBlurEffectAsync() {
        DispatchQueue.main.async { [weak self] in
            self?.animator?.startAnimation()
        }
    }
}
