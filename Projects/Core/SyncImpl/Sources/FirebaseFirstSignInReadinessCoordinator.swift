//
//  FirebaseFirstSignInReadinessCoordinator.swift
//  NoteCard
//

import Combine
import Foundation
import SyncInterface

public final class FirebaseFirstSignInReadinessCoordinator: FirstSignInReadinessCoordinator, @unchecked Sendable {

    private let cleanupCoordinator: AnonymousMigrationCleanupCoordinator
    private let memoRouter: MemoRepositoryRouter
    private let categoryRouter: CategoryRepositoryRouter

    private let phaseSubject = CurrentValueSubject<SignInPhase, Never>(.idle)
    public var phasePublisher: AnyPublisher<SignInPhase, Never> {
        phaseSubject.eraseToAnyPublisher()
    }

    public init(
        cleanupCoordinator: AnonymousMigrationCleanupCoordinator,
        memoRouter: MemoRepositoryRouter,
        categoryRouter: CategoryRepositoryRouter
    ) {
        self.cleanupCoordinator = cleanupCoordinator
        self.memoRouter = memoRouter
        self.categoryRouter = categoryRouter
    }

    public func reportSigningIn() {
        phaseSubject.send(.signingIn)
    }

    public func reset() {
        phaseSubject.send(.idle)
    }

    public func awaitReady(userID: String, timeout: TimeInterval) async throws {
        phaseSubject.send(.uploading)
        do {
            try await waitForCleanup(userID: userID, timeout: timeout)
        } catch {
            phaseSubject.send(.idle)
            throw error
        }

        phaseSubject.send(.downloading)
        do {
            try await waitForInitialSync(timeout: timeout)
        } catch {
            phaseSubject.send(.idle)
            throw error
        }

        phaseSubject.send(.ready)
    }

    private func waitForCleanup(userID: String, timeout: TimeInterval) async throws {
        let cleanupMarkerKey = "sync.anonymousMigrationCleanup.\(userID)"
        if UserDefaults.standard.bool(forKey: cleanupMarkerKey) {
            return
        }

        try await withTimeout(seconds: timeout) {
            await self.cleanupCoordinator.cleanupCompletedPublisher
                .filter { $0 == userID }
                .firstValue()
        }
    }

    private func waitForInitialSync(timeout: TimeInterval) async throws {
        try await withTimeout(seconds: timeout) {
            await Publishers.CombineLatest(
                self.memoRouter.initialServerSyncPublisher,
                self.categoryRouter.initialServerSyncPublisher
            )
            .first(where: { $0 && $1 })
            .firstValue()
        }
    }

    private func withTimeout<T: Sendable>(seconds: TimeInterval, _ work: @escaping @Sendable () async -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T?.self) { group in
            group.addTask {
                await work()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw SignInReadinessError.timeout
            }
            guard let result = try await group.next(), let value = result else {
                throw SignInReadinessError.timeout
            }
            group.cancelAll()
            return value
        }
    }
}

private extension Publisher where Failure == Never {
    func firstValue() async -> Output {
        await withCheckedContinuation { continuation in
            var resumed = false
            var cancellable: AnyCancellable?
            cancellable = self.first().sink(
                receiveCompletion: { _ in
                    cancellable?.cancel()
                },
                receiveValue: { value in
                    guard !resumed else { return }
                    resumed = true
                    cancellable?.cancel()
                    continuation.resume(returning: value)
                }
            )
        }
    }
}
