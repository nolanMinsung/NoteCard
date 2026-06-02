//
//  SyncStatusService.swift
//  NoteCard
//

import Combine
import Foundation

/// 현재 기기의 동기화 상태를 표면화하는 서비스. AccountDetail 등 UI 가 구독해 사용자에게 표시.
///
/// 본 v1 구현은 인증 상태 + Memo / Category publisher 의 이벤트 도착 시점만 가지고 상태를 단순 추정.
/// 향후 확장 여지: Firestore listener metadata (hasPendingWrites / isFromCache) 직접 노출,
/// 네트워크 reachability 감지로 `.offline` 도입, listener PERMISSION_DENIED 신호로 `.error` 도입.
public protocol SyncStatusService: AnyObject, Sendable {

    /// 현재 동기화 상태. UI binding 용.
    var statusPublisher: AnyPublisher<SyncStatus, Never> { get }

    /// 마지막으로 서버 데이터를 받은 시점. 사인아웃 / 미수신 시 nil.
    var lastSyncedAtPublisher: AnyPublisher<Date?, Never> { get }
}

public enum SyncStatus: Equatable, Sendable {
    /// 미사인인 또는 초기 상태. UI 는 placeholder 표시.
    case unknown
    /// 로그인 직후 또는 listener 가 첫 스냅샷을 아직 못 받은 상태.
    case syncing
    /// 최근 서버 이벤트를 받음.
    case synced
}
