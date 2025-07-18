//
//  UIWindow+.swift
//  NoteCard
//
//  Created by 김민성 on 7/18/25.
//

import UIKit


extension UIWindow {
    static var current: UIWindow? {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else {
                print("UIApplication.shared.connectedScenes is nil")
                fatalError()
            }
            for window in windowScene.windows {
                if window.isKeyWindow { return window }
            }
        }
        fatalError()
    }
}
