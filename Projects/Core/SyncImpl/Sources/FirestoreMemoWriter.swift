//
//  FirestoreMemoWriter.swift
//  NoteCard
//

import Domain
import FirebaseFirestore
import Foundation

/// 메모 원격 쓰기 표면. `FirestoreSyncService`가 의존하며, 테스트에서 Firestore 실호출을
/// 대체(mock)하기 위한 내부 seam. 모듈 외부로 노출하지 않는다.
protocol MemoRemoteWriting: Sendable {
    func upsert(_ memo: Memo, userID: String) async throws
    func delete(memoID: UUID, userID: String) async throws
}

/// Firestore에 메모 문서를 push하는 얇은 wrapper.
///
/// Document path: `users/{userID}/memos/{memoID}`. 페이로드는 `FirestoreMemo` Codable DTO를
/// `Firestore.Encoder`로 인코딩한 dictionary에 server timestamp(`serverUpdatedAt`)를 더한다.
/// `setData(merge: true)`라 서버에만 존재하는 필드(다른 기기가 추가한 미래 필드 등)는 보존된다.
public final class FirestoreMemoWriter: MemoRemoteWriting, @unchecked Sendable {

    private let firestore: Firestore

    public init(firestore: Firestore = .firestore()) {
        self.firestore = firestore
    }

    /// 주어진 메모를 인증된 사용자의 store에 upsert한다.
    public func upsert(_ memo: Memo, userID: String) async throws {
        let payload = try Self.payload(for: memo)
        try await memoDocument(memoID: memo.memoID, userID: userID).setData(payload, merge: true)
    }

    /// 영구 삭제 메모는 로컬에서 이미 사라져 fetch가 불가능하므로 memoID로 직접 삭제한다.
    public func delete(memoID: UUID, userID: String) async throws {
        try await memoDocument(memoID: memoID, userID: userID).delete()
    }

    private func memoDocument(memoID: UUID, userID: String) -> DocumentReference {
        firestore
            .collection("users").document(userID)
            .collection("memos").document(memoID.uuidString)
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
