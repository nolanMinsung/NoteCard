//
//  FirestoreMemoImage.swift
//  NoteCard
//

import Domain
import Foundation

/// Firestore에 저장되는 이미지 메타데이터 문서의 스키마.
///
/// Document path: `users/{uid}/memos/{memoID}/images/{imageID}` (메모의 sub-collection).
/// 바이너리(원본·썸네일)는 Firebase Storage에서 별도 관리:
/// - 원본: `users/{uid}/memos/{memoID}/{imageID}.<fileExtension>`
/// - 썸네일: `users/{uid}/memos/{memoID}/{thumbnailID}.jpeg`
///
/// 도메인 `MemoImageInfo`의 임시 편집 상태 필드(`temporaryOrderIndex`·`isTemporaryAppended`·`isTemporaryDeleted`)는
/// UI 메모리에서만 사용되고 저장 시점엔 항상 settled 값(각각 `orderIndex`·`false`·`false`)으로 정착되므로
/// 본 DTO에서 제외. `toDomain()` 복원 시 그 settled 기본값으로 채워 동작은 동일.
public struct FirestoreMemoImage: Codable, Equatable, Sendable {
    public let imageID: String
    public let thumbnailID: String
    public let memoID: String
    public let orderIndex: Int
    public let fileExtension: String
}

public extension FirestoreMemoImage {

    init(_ info: MemoImageInfo) {
        self.imageID = info.id.uuidString
        self.thumbnailID = info.thumbnailID.uuidString
        self.memoID = info.memoID.uuidString
        self.orderIndex = info.orderIndex
        self.fileExtension = info.fileExtension
    }

    /// 서버 DTO를 로컬 `MemoImageInfo`로 되돌린다. UUID 파싱 실패 시 `nil`.
    /// 임시 편집 상태 필드는 settled 기본값으로 채움.
    func toDomain() -> MemoImageInfo? {
        guard
            let id = UUID(uuidString: imageID),
            let thumbnailUUID = UUID(uuidString: thumbnailID),
            let memoUUID = UUID(uuidString: memoID)
        else { return nil }
        return MemoImageInfo(
            id: id,
            thumbnailID: thumbnailUUID,
            temporaryOrderIndex: orderIndex,
            orderIndex: orderIndex,
            memoID: memoUUID,
            isTemporaryDeleted: false,
            isTemporaryAppended: false,
            fileExtension: fileExtension
        )
    }
}
