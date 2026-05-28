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
        guard startSubscription() else { return }
        // No-op AuthService처럼 첫 값을 즉시 emit하지 않는 publisher 대비 — 현재 상태 한 번 명시 반영.
        handleAuthChange(user: authService.currentUser)
    }

    /// 인증 구독을 해제하고 `.disconnected`로 전이. listener를 정리하는 자리(후속 단계에서 확장).
    public func stop() async {
        cancelSubscription()?.cancel()
        statusSubject.send(.disconnected)
    }

    /// `stateLock` 구간을 동기 메서드로 격리한다.
    ///
    /// `NSLock.lock()`/`unlock()`은 async 컨텍스트에서 호출 시 suspension point를 가로질러
    /// acquire/release 스레드가 달라질 수 있어 unavailable(Swift 6에선 error). lock 구간을
    /// suspension이 없는 동기 메서드 안에 가두면 그 위험이 원천 차단된다.
    /// - Returns: 이번 호출로 새로 구독을 시작했으면 `true`, 이미 시작돼 있었으면 `false`.
    private func startSubscription() -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard _authCancellable == nil else { return false }
        _authCancellable = authService.authStatePublisher
            .sink { [weak self] user in
                self?.handleAuthChange(user: user)
            }
        return true
    }

    /// 구독을 해제하고 직전 cancellable을 반환한다(`cancel()`은 lock 밖에서 호출하도록 위임).
    private func cancelSubscription() -> AnyCancellable? {
        stateLock.lock()
        defer { stateLock.unlock() }
        let previous = _authCancellable
        _authCancellable = nil
        return previous
    }

    private func handleAuthChange(user: AuthUser?) {
        statusSubject.send(user == nil ? .disconnected : .upToDate)
    }
}
