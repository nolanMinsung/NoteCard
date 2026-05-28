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

    case create(memoIDs: [UUID])
    case trash(memoIDs: [UUID])
    case delete(memoIDs: [UUID])
    case restore(memoIDs: [UUID])
    case update(content: UpdateAttribute)

    /// 이벤트가 가리키는 대상 메모 ID들. 동기화가 어떤 메모를 push/삭제할지 식별하는 데 사용.
    public var memoIDs: [UUID] {
        switch self {
        case .create(let memoIDs): return memoIDs
        case .trash(let memoIDs): return memoIDs
        case .delete(let memoIDs): return memoIDs
        case .restore(let memoIDs): return memoIDs
        case .update(let content): return content.memoIDs
        }
    }
}
