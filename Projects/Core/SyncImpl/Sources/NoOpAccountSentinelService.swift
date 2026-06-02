//
//  NoOpAccountSentinelService.swift
//  NoteCard
//

import Foundation
import SyncInterface

/// Firebase 미설정 환경에서 사용. 모든 메서드는 no-op.
public final class NoOpAccountSentinelService: AccountSentinelService, @unchecked Sendable {
    public init() {}
    public func deleteSentinel() async throws {}
}
