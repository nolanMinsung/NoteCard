//
//  CategoryUpdateType.swift
//  NoteCard
//

import Foundation

/// `CategoryRepository`가 발행하는 카테고리 변경 이벤트의 종류.
public enum CategoryUpdateType: Equatable {
    public enum UpdateAttribute: Equatable {
        case name(categoryIDs: [UUID])
        case modificationDate(categoryIDs: [UUID])

        public var categoryIDs: [UUID] {
            switch self {
            case .name(let categoryIDs): return categoryIDs
            case .modificationDate(let categoryIDs): return categoryIDs
            }
        }
    }

    case create
    case delete
    case update(content: UpdateAttribute)
}
