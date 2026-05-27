//
//  NoOpSyncService.swift
//  NoteCard
//

import Combine
import Foundation
import SyncInterface

/// 동기화를 비활성화하는 no-op 구현.
///
/// Firebase 설정(`GoogleService-Info.plist`)이 없는 환경(CI 빌드, 미설정 등)에서
/// `SyncBootstrap`이 fallback으로 사용한다. status는 영구히 `.disconnected`.
public final class NoOpSyncService: SyncService, @unchecked Sendable {
    public init() {}

    public var currentStatus: SyncStatus { .disconnected }

    public var statusPublisher: AnyPublisher<SyncStatus, Never> {
        Just(.disconnected).eraseToAnyPublisher()
    }

    public func start() async {}
    public func stop() async {}
}
