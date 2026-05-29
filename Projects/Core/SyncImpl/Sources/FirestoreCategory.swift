//
//  FirestoreCategory.swift
//  NoteCard
//

import Domain
import Foundation

/// Firestore에 저장되는 카테고리 문서의 스키마.
///
/// Document path: `users/{uid}/categories/{categoryID}`.
/// `serverUpdatedAt`은 Firestore에 쓸 때 `FieldValue.serverTimestamp()`로 채우는 보조 timestamp라
/// 이 DTO에는 포함하지 않는다. 카테고리는 다른 엔티티를 참조하지 않아 메모와 달리 관계 필드가 없다.
public struct FirestoreCategory: Codable, Equatable, Sendable {
    public let categoryID: String
    public let name: String
    public let creationDate: Date
    public let modificationDate: Date
}

public extension FirestoreCategory {

    init(_ category: Domain.Category) {
        self.categoryID = category.id.uuidString
        self.name = category.name
        self.creationDate = category.creationDate
        self.modificationDate = category.modificationDate
    }

    /// 서버 DTO를 로컬 `Category`로 되돌린다. `categoryID`가 UUID로 파싱되지 않으면(손상 문서) `nil`.
    func toDomain() -> Domain.Category? {
        guard let id = UUID(uuidString: categoryID) else { return nil }
        return Domain.Category(
            id: id,
            name: name,
            creationDate: creationDate,
            modificationDate: modificationDate
        )
    }
}
