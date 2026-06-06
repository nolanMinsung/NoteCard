//
//  FirebaseSignOutCoordinator.swift
//  NoteCard
//

import Combine
import Foundation
import SyncInterface

public final class FirebaseSignOutCoordinator: SignOutCoordinator, @unchecked Sendable {

    private let authService: AuthService
    private let phaseSubject = CurrentValueSubject<SignOutPhase, Never>(.idle)

    public var phasePublisher: AnyPublisher<SignOutPhase, Never> {
        phaseSubject.eraseToAnyPublisher()
    }

    public init(authService: AuthService) {
        self.authService = authService
    }

    public func performSignOut() async throws {
        phaseSubject.send(.signingOut)
        defer { phaseSubject.send(.idle) }
        try await authService.signOut()
    }
}
