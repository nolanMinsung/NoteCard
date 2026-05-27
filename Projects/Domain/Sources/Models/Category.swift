//
//  Category.swift
//  NoteCard
//
//  Created by 김민성 on 8/27/25.
//

import Foundation
import Shared

public struct Category: Hashable, Sendable {
    public let id: UUID
    public var name: String
    public let creationDate: Date
    public var modificationDate: Date

    public init(id: UUID, name: String, creationDate: Date, modificationDate: Date) {
        self.id = id
        self.name = name
        self.creationDate = creationDate
        self.modificationDate = modificationDate
    }
}

extension Category: Comparable {

    public static func <(lhs: Category, rhs: Category) -> Bool {
        if lhs.modificationDate == rhs.modificationDate {
            return lhs.creationDate < rhs.creationDate
        } else {
            return (lhs.modificationDate < rhs.modificationDate)
        }
    }

}
