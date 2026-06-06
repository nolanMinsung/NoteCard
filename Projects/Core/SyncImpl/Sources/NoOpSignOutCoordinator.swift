//
//  NoOpSignOutCoordinator.swift
//  NoteCard
//

import Combine
import Foundation
import SyncInterface

public final class NoOpSignOutCoordinator: SignOutCoordinator, @unchecked Sendable {

    private let phaseSubject = CurrentValueSubject<SignOutPhase, Never>(.idle)
    public var phasePublisher: AnyPublisher<SignOutPhase, Never> {
        phaseSubject.eraseToAnyPublisher()
    }

    public init() {}

    public func performSignOut() async throws {}
}
