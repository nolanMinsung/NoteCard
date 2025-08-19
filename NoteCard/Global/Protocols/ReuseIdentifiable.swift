//
//  ReuseIdentifiable.swift
//  NoteCard
//
//  Created by 김민성 on 4/6/25.
//

protocol ReuseIdentifiable {
    static var reuseIdentifier: String { get }
}

extension ReuseIdentifiable {
    static var reuseIdentifier: String {
        String(describing: self)
    }
}
