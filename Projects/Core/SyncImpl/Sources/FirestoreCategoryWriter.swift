//
//  FirestoreCategoryWriter.swift
//  NoteCard
//

import Domain
import FirebaseFirestore
import Foundation

/// 카테고리 원격 쓰기 표면. `FirestoreSyncService`가 의존하며, 테스트에서 Firestore 실호출을
/// 대체(mock)하기 위한 내부 seam. 모듈 외부로 노출하지 않는다.
protocol CategoryRemoteWriting: Sendable {
    func upsert(_ category: Domain.Category, userID: String) async throws
    func delete(categoryID: UUID, userID: String) async throws
}

/// Firestore에 카테고리 문서를 push하는 얇은 wrapper.
///
/// Document path: `users/{userID}/categories/{categoryID}`. `setData(merge: true)`라
/// 서버에만 존재하는 미래 필드는 보존된다. 카테고리는 nil이 될 수 있는 필드가 없어 메모처럼
/// `FieldValue.delete()`로 정리할 항목은 없다.
public final class FirestoreCategoryWriter: CategoryRemoteWriting, @unchecked Sendable {

    private let firestore: Firestore

    public init(firestore: Firestore = .firestore()) {
        self.firestore = firestore
    }

    public func upsert(_ category: Domain.Category, userID: String) async throws {
        let payload = try Self.payload(for: category)
        try await categoryDocument(categoryID: category.id, userID: userID).setData(payload, merge: true)
    }

    public func delete(categoryID: UUID, userID: String) async throws {
        try await categoryDocument(categoryID: categoryID, userID: userID).delete()
    }

    private func categoryDocument(categoryID: UUID, userID: String) -> DocumentReference {
        firestore
            .collection("users").document(userID)
            .collection("categories").document(categoryID.uuidString)
    }

    /// Firestore에 쓸 dictionary 페이로드. server timestamp(`serverUpdatedAt`)는 SDK sentinel로 넣고
    /// 실제 시각은 Firestore가 commit 시점에 채운다.
    static func payload(for category: Domain.Category) throws -> [String: Any] {
        var dict = try Firestore.Encoder().encode(FirestoreCategory(category))
        dict["serverUpdatedAt"] = FieldValue.serverTimestamp()
        return dict
    }
}
