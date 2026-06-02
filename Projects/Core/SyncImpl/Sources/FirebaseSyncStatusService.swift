//
//  FirebaseSyncStatusService.swift
//  NoteCard
//

import Combine
import Domain
import Foundation
import SyncInterface

/// 인증 상태 + Memo / Category publisher 이벤트로 동기화 상태를 추정하는 단순 구현.
///
/// 동작:
/// - 사인아웃: `.unknown` + lastSyncedAt = nil.
/// - 사인인: 즉시 `.syncing` (이벤트 도착 전).
/// - Memo / Category 이벤트 첫 도착 이후: `.synced` + lastSyncedAt 갱신.
public final class FirebaseSyncStatusService: SyncStatusService, @unchecked Sendable {

    private let statusSubject = CurrentValueSubject<SyncStatus, Never>(.unknown)
    private let lastSyncedAtSubject = CurrentValueSubject<Date?, Never>(nil)

    public var statusPublisher: AnyPublisher<SyncStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }
    public var lastSyncedAtPublisher: AnyPublisher<Date?, Never> {
        lastSyncedAtSubject.eraseToAnyPublisher()
    }

    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()

    public init(
        authService: AuthService,
        memoRepository: MemoRepository,
        categoryRepository: CategoryRepository
    ) {
        self.authService = authService

        authService.authStatePublisher
            .sink { [weak self] user in
                guard let self else { return }
                if user != nil {
                    self.statusSubject.send(.syncing)
                } else {
                    self.statusSubject.send(.unknown)
                    self.lastSyncedAtSubject.send(nil)
                }
            }
            .store(in: &cancellables)

        memoRepository.memoUpdatedPublisher
            .sink { [weak self] _ in self?.recordSync() }
            .store(in: &cancellables)

        categoryRepository.categoryUpdatedPublisher
            .sink { [weak self] _ in self?.recordSync() }
            .store(in: &cancellables)
    }

    private func recordSync() {
        guard authService.currentUser != nil else { return }
        statusSubject.send(.synced)
        lastSyncedAtSubject.send(Date())
    }
}
