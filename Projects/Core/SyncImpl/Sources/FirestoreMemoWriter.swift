//
//  FirestoreMemoWriter.swift
//  NoteCard
//

import Domain
import FirebaseFirestore
import Foundation

/// Firestore에 메모 문서를 push하는 얇은 wrapper.
///
/// Document path: `users/{userID}/memos/{memoID}`. 페이로드는 `FirestoreMemo` Codable DTO를
/// `Firestore.Encoder`로 인코딩한 dictionary에 server timestamp(`serverUpdatedAt`)를 더한다.
/// `setData(merge: true)`라 서버에만 존재하는 필드(다른 기기가 추가한 미래 필드 등)는 보존된다.
public final class FirestoreMemoWriter: @unchecked Sendable {

    private let firestore: Firestore

    public init(firestore: Firestore = .firestore()) {
        self.firestore = firestore
    }

    /// 주어진 메모를 인증된 사용자의 store에 upsert한다.
    public func upsert(_ memo: Memo, userID: String) async throws {
        let payload = try Self.payload(for: memo)
        let docRef = firestore
            .collection("users").document(userID)
            .collection("memos").document(memo.memoID.uuidString)
        try await docRef.setData(payload, merge: true)
    }

    /// Firestore에 쓸 dictionary 페이로드를 만든다.
    ///
    /// 단위 테스트가 가능하도록 분리. 서버 timestamp는 SDK sentinel(`FieldValue.serverTimestamp()`)을
    /// 그대로 넣고, 실제 시각은 Firestore가 commit 시점에 채운다. `deletedDate`가 nil일 때는
    /// `setData(merge: true)`가 기존 필드를 보존하므로, 휴지통 복원 후에도 옛 값이 남지 않도록
    /// 명시적 `FieldValue.delete()`를 push한다.
    static func payload(for memo: Memo) throws -> [String: Any] {
        var dict = try Firestore.Encoder().encode(FirestoreMemo(memo))
        if memo.deletedDate == nil {
            dict["deletedDate"] = FieldValue.delete()
        }
        dict["serverUpdatedAt"] = FieldValue.serverTimestamp()
        return dict
    }
}
