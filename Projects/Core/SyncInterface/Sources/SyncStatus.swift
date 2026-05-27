//
//  SyncStatus.swift
//  NoteCard
//

import Foundation

/// 동기화 상태. UI에 노출 가능한 4-케이스.
///
/// - `disconnected`: 로그아웃 상태이거나 사용자가 동기화를 끈 상태. 클라우드와의 어떤 연결도 없음.
/// - `upToDate`: 마지막 sync가 성공적으로 끝나 로컬과 서버가 동일.
/// - `syncing`: push/pull/listener 이벤트 처리가 진행 중.
/// - `error`: 마지막 작업이 실패. 연관된 `SyncError`로 사용자 안내 가능.
public enum SyncStatus: Equatable {
    case disconnected
    case upToDate
    case syncing
    case error(SyncError)

    public static func == (lhs: SyncStatus, rhs: SyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.upToDate,     .upToDate),
             (.syncing,      .syncing):
            return true
        case (.error(let l), .error(let r)):
            return String(describing: l) == String(describing: r)
        default:
            return false
        }
    }
}
