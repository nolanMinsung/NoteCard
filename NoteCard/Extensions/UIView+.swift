//
//  UIView+.swift
//  NoteCard
//
//  Created by 김민성 on 7/17/25.
//

import UIKit


extension UIView {
    
    static func springAnimate(withDuration: TimeInterval, delay: TimeInterval = 0, animations: @escaping () -> Void) {
        self.animate(withDuration: withDuration, delay: delay, usingSpringWithDamping: 1, initialSpringVelocity: 1, animations: animations)
    }
    
    func currentWindowScene() -> UIWindowScene? {
        guard let window = self.window else { return nil }
        guard let windowScene = window.windowScene else { return nil }
        return windowScene
    }
    
}
