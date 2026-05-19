//
//  MemoUpdateType.swift
//  NoteCard
//

import Foundation

/// `MemoRepository`가 발행하는 메모 변경 이벤트의 종류.
public enum MemoUpdateType: Equatable {
    public enum UpdateAttribute: Equatable {
        case favorite(memoIDs: [UUID])
        case titleText(memoIDs: [UUID])
        case category(memoIDs: [UUID])

        public var memoIDs: [UUID] {
            switch self {
            case .favorite(let memoIDs): return memoIDs
            case .titleText(let memoIDs): return memoIDs
            case .category(let memoIDs): return memoIDs
            }
        }
    }

    case create
    case trash
    case delete
    case restore
    case update(content: UpdateAttribute)
}
