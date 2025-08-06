//
//  UIColor+DesignSystem.swift
//  NoteCard
//
//  Created by 김민성 on 8/6/25.
//

import UIKit

extension UIColor {
    
    static let homeViewBackground = UIColor { traitCollection in
        return (traitCollection.userInterfaceStyle == .dark) ? .black : .systemGray6
    }
    
}
