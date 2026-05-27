//
//  FirestoreSyncService.swift
//  NoteCard
//

import Combine
import Foundation
import SyncInterface

/// Firestore 기반 `SyncService` 구현.
///
/// 본 단계의 책임은 status 노출과 인증 상태 동기화 lifecycle만이며, 실제 push/pull 로직(메모·카테고리·이미지)은
/// 후속에서 결합된다. 인증된 사용자가 있으면 `.upToDate`, 없으면 `.disconnected`로 status를 자동 전이.
public final class FirestoreSyncService: SyncService, @unchecked Sendable {

    private let authService: AuthService
    private let statusSubject = CurrentValueSubject<SyncStatus, Never>(.disconnected)
    private let stateLock = NSLock()
    /// `stateLock`으로 보호되는 mutable state. 직접 접근 금지.
    private var _authCancellable: AnyCancellable?

    public init(authService: AuthService) {
        self.authService = authService
    }

    public var currentStatus: SyncStatus { statusSubject.value }

    public var statusPublisher: AnyPublisher<SyncStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    /// 인증 상태 구독을 시작한다. 이미 시작된 상태면 no-op (idempotent).
    public func start() async {
        stateLock.lock()
        guard _authCancellable == nil else {
            stateLock.unlock()
            return
        }
        let cancellable = authService.authStatePublisher
            .sink { [weak self] user in
                self?.handleAuthChange(user: user)
            }
        _authCancellable = cancellable
        stateLock.unlock()
        // No-op AuthService처럼 첫 값을 즉시 emit하지 않는 publisher 대비 — 현재 상태 한 번 명시 반영.
        handleAuthChange(user: authService.currentUser)
    }

    /// 인증 구독을 해제하고 `.disconnected`로 전이. listener를 정리하는 자리(후속 단계에서 확장).
    public func stop() async {
        stateLock.lock()
        let previous = _authCancellable
        _authCancellable = nil
        stateLock.unlock()
        previous?.cancel()
        statusSubject.send(.disconnected)
    }

    private func handleAuthChange(user: AuthUser?) {
        statusSubject.send(user == nil ? .disconnected : .upToDate)
    }
}
