//
//  ImageUpdateType.swift
//  NoteCard
//

import Foundation

/// `ImageRepository`가 발행하는 이미지 변경 이벤트의 종류.
public enum ImageUpdateType: Equatable {
    case create(memoID: UUID)
    case delete(memoID: UUID)
    case update(memoID: UUID)

    public var memoID: UUID {
        switch self {
        case .create(let memoID):
            return memoID
        case .delete(let memoID):
            return memoID
        case .update(let memoID):
            return memoID
        }
    }
}
