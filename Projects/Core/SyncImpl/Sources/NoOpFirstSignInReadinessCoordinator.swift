//
//  NoOpFirstSignInReadinessCoordinator.swift
//  NoteCard
//

import Combine
import Foundation
import SyncInterface

/// Firebase 미설정 환경에서 사용. 모든 메서드 즉시 반환 / no-op.
public final class NoOpFirstSignInReadinessCoordinator: FirstSignInReadinessCoordinator, @unchecked Sendable {

    private let phaseSubject = CurrentValueSubject<SignInPhase, Never>(.idle)
    public var phasePublisher: AnyPublisher<SignInPhase, Never> {
        phaseSubject.eraseToAnyPublisher()
    }

    public init() {}

    public func reportSigningIn() {}
    public func reset() {}
    public func awaitReady(userID: String, timeout: TimeInterval) async throws {}
}
