//
//  UIScreen+.swift
//  NoteCard
//
//  Created by 김민성 on 7/18/25.
//

import UIKit


extension UIScreen {
    static var current: UIScreen? {
        UIWindow.current?.screen
    }
}

