//
//  NoOpSyncStatusService.swift
//  NoteCard
//

import Combine
import Foundation
import SyncInterface

/// Firebase 미설정 환경에서 사용. 항상 unknown 상태를 emit.
public final class NoOpSyncStatusService: SyncStatusService, @unchecked Sendable {
    public init() {}

    public var statusPublisher: AnyPublisher<SyncStatus, Never> {
        Just(.unknown).eraseToAnyPublisher()
    }
    public var lastSyncedAtPublisher: AnyPublisher<Date?, Never> {
        Just(nil).eraseToAnyPublisher()
    }
}
