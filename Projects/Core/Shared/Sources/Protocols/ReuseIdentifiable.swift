//
//  ReuseIdentifiable.swift
//  NoteCard
//
//  Created by 김민성 on 4/6/25.
//

import UIKit

public protocol ReuseIdentifiable {
    static var reuseIdentifier: String { get }
}

public extension ReuseIdentifiable {
    static var reuseIdentifier: String {
        String(describing: self)
    }
}

extension UICollectionReusableView: ReuseIdentifiable { }
