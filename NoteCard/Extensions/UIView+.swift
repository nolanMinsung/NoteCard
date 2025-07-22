//
//  UIView+.swift
//  NoteCard
//
//  Created by 김민성 on 7/17/25.
//

import UIKit


extension UIView {
    
    static func springAnimate(
        withDuration: TimeInterval,
        delay: TimeInterval = 0,
        options: AnimationOptions = [],
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        self.animate(
            withDuration: withDuration,
            delay: delay,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 1,
            options: options,
            animations: animations,
            completion: completion
        )
    }
    
    func currentWindowScene() -> UIWindowScene? {
        guard let window = self.window else { return nil }
        guard let windowScene = window.windowScene else { return nil }
        return windowScene
    }
    
    // window가 여러 개인 경우는 어떡함?
    func currentSceneSize() -> CGSize? {
        return currentWindowScene()?.windows.first?.bounds.size
    }
    
}
