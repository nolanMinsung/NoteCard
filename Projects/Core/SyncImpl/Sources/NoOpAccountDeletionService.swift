//
//  NoOpAccountDeletionService.swift
//  NoteCard
//

import Combine
import Foundation
import SyncInterface

/// Firebase 미설정 환경에서 사용. 호출 시 `missingFirebase` 던짐.
public final class NoOpAccountDeletionService: AccountDeletionService, @unchecked Sendable {

    private let phaseSubject = CurrentValueSubject<AccountDeletionPhase, Never>(.idle)
    public var phasePublisher: AnyPublisher<AccountDeletionPhase, Never> {
        phaseSubject.eraseToAnyPublisher()
    }

    public init() {}

    public func deleteAccountAndAllData() async throws {
        throw AuthError.missingFirebase
    }
}
