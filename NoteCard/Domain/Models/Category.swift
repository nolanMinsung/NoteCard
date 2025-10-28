//
//  Category.swift
//  NoteCard
//
//  Created by 김민성 on 8/27/25.
//

import Foundation

struct Category: Hashable {
    var name: String
    let creationDate: Date
    var modificationDate: Date
}

extension Category: Comparable {
    
    static func <(lhs: Category, rhs: Category) -> Bool {
        if lhs.modificationDate == rhs.modificationDate {
            return lhs.creationDate < rhs.creationDate
        } else {
            return (lhs.modificationDate < rhs.modificationDate)
        }
    }
    
}
