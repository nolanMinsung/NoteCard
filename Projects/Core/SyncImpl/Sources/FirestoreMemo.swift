//
//  FirestoreMemo.swift
//  NoteCard
//

import Domain
import Foundation

/// Firestore에 저장되는 메모 문서의 평면 스키마.
///
/// Document path: `users/{uid}/memos/{memoID}`.
/// `serverUpdatedAt`은 Firestore에 쓸 때 `FieldValue.serverTimestamp()`로 채워지는 보조 timestamp로,
/// 매퍼 책임 밖이라 이 DTO에는 포함하지 않는다. 카테고리 본문(이름·생성일 등)도 별도 컬렉션으로
/// 분리되며, 메모 문서에는 관계 유지를 위한 `categoryIDs`만 보관한다. 이미지 메타·바이너리는
/// 메모 sub-collection / Storage로 별도 관리되므로 본 DTO에는 포함하지 않는다.
public struct FirestoreMemo: Codable, Equatable, Sendable {
    public let memoID: String
    public let memoTitle: String
    public let memoText: String
    public let isFavorite: Bool
    public let isInTrash: Bool
    public let creationDate: Date
    public let modificationDate: Date
    public let deletedDate: Date?
    public let categoryIDs: [String]
}

public extension FirestoreMemo {

    /// Domain `Memo`로부터 Firestore 페이로드를 만든다. `categoryIDs`는 안정적 비교/직렬화를 위해
    /// uuidString 사전순으로 정렬해 저장한다.
    init(_ memo: Memo) {
        self.memoID = memo.memoID.uuidString
        self.memoTitle = memo.memoTitle
        self.memoText = memo.memoText
        self.isFavorite = memo.isFavorite
        self.isInTrash = memo.isInTrash
        self.creationDate = memo.creationDate
        self.modificationDate = memo.modificationDate
        self.deletedDate = memo.deletedDate
        self.categoryIDs = memo.categories.map(\.id.uuidString).sorted()
    }
}
