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

    case create(categoryIDs: [UUID])
    case delete(categoryIDs: [UUID])
    case update(content: UpdateAttribute)

    /// 이벤트가 가리키는 대상 카테고리 ID들. 동기화가 어떤 카테고리를 push/삭제할지 식별하는 데 사용.
    public var categoryIDs: [UUID] {
        switch self {
        case .create(let categoryIDs): return categoryIDs
        case .delete(let categoryIDs): return categoryIDs
        case .update(let content): return content.categoryIDs
        }
    }
}
