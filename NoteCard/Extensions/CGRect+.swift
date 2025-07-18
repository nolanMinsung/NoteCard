//
//  CGRect+.swift
//  NoteCard
//
//  Created by 김민성 on 7/18/25.
//

import UIKit


extension CGRect {
    var center: CGPoint {
        get { return CGPoint(x: self.origin.x + self.width / 2, y: self.origin.y + self.height / 2) }
        set { self.origin = CGPoint(x: newValue.x - self.width / 2, y: newValue.y - self.height / 2) }
    }
}
