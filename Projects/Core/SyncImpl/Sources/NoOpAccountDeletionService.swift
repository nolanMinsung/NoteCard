//
//  NoOpAccountDeletionService.swift
//  NoteCard
//

import Foundation
import SyncInterface

/// Firebase 미설정 환경에서 사용. 호출 시 `missingFirebase` 던짐.
public final class NoOpAccountDeletionService: AccountDeletionService, @unchecked Sendable {
    public init() {}

    public func deleteAccountAndAllData() async throws {
        throw AuthError.missingFirebase
    }
}
