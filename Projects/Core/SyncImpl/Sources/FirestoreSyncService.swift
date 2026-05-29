//
//  FirestoreSyncService.swift
//  NoteCard
//

import Combine
import Domain
import Foundation
import SyncInterface

/// Firestore 기반 `SyncService` 구현.
///
/// status 노출과 인증 상태 lifecycle에 더해, 메모 변경 이벤트를 받아 Firestore로 단방향 push한다.
/// 인증된 사용자가 있으면 `.upToDate`, 없으면 `.disconnected`로 status를 자동 전이.
/// (pull(listener)·디바운스·에러 status 전이는 후속 단계에서 결합.)
public final class FirestoreSyncService: SyncService, @unchecked Sendable {

    /// 메모 변경 이벤트를 Firestore 작업으로 환산한 결과.
    enum MemoSyncAction: Equatable {
        case upsert(memoIDs: [UUID])
        case delete(memoIDs: [UUID])
    }

    private let authService: AuthService
    private let memoRepository: MemoRepository
    private let memoWriter: MemoRemoteWriting

    private let statusSubject = CurrentValueSubject<SyncStatus, Never>(.disconnected)
    private let stateLock = NSLock()
    /// `stateLock`으로 보호되는 mutable state. 직접 접근 금지.
    private var _authCancellable: AnyCancellable?
    private var _memoCancellable: AnyCancellable?

    init(
        authService: AuthService,
        memoRepository: MemoRepository,
        memoWriter: MemoRemoteWriting
    ) {
        self.authService = authService
        self.memoRepository = memoRepository
        self.memoWriter = memoWriter
    }

    public var currentStatus: SyncStatus { statusSubject.value }

    public var statusPublisher: AnyPublisher<SyncStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    /// 인증 상태·메모 변경 구독을 시작한다. 이미 시작된 상태면 no-op (idempotent).
    public func start() async {
        guard startSubscriptions() else { return }
        // No-op AuthService처럼 첫 값을 즉시 emit하지 않는 publisher 대비 — 현재 상태 한 번 명시 반영.
        handleAuthChange(user: authService.currentUser)
    }

    /// 구독을 모두 해제하고 `.disconnected`로 전이. listener를 정리하는 자리(후속 단계에서 확장).
    public func stop() async {
        let cancellables = cancelSubscriptions()
        cancellables.forEach { $0.cancel() }
        statusSubject.send(.disconnected)
    }

    /// 메모 변경 이벤트를 Firestore 작업으로 환산한다.
    static func syncAction(for event: MemoUpdateType) -> MemoSyncAction {
        switch event {
        case .delete(let memoIDs):
            return .delete(memoIDs: memoIDs)
        case .create, .trash, .restore, .update:
            return .upsert(memoIDs: event.memoIDs)
        }
    }

    // MARK: - Lock 격리 (async-context에서 NSLock 직접 사용 회피)

    /// `stateLock` 구간을 동기 메서드로 격리한다.
    /// - Returns: 이번 호출로 새로 구독을 시작했으면 `true`, 이미 시작돼 있었으면 `false`.
    private func startSubscriptions() -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard _authCancellable == nil else { return false }
        _authCancellable = authService.authStatePublisher
            .sink { [weak self] user in
                self?.handleAuthChange(user: user)
            }
        _memoCancellable = memoRepository.memoUpdatedPublisher
            .sink { [weak self] event in
                self?.handleMemoEvent(event)
            }
        return true
    }

    /// 구독들을 해제하고 직전 cancellable들을 반환한다(`cancel()`은 lock 밖에서 호출하도록 위임).
    private func cancelSubscriptions() -> [AnyCancellable] {
        stateLock.lock()
        defer { stateLock.unlock() }
        let previous = [_authCancellable, _memoCancellable].compactMap { $0 }
        _authCancellable = nil
        _memoCancellable = nil
        return previous
    }

    // MARK: - 이벤트 처리

    private func handleAuthChange(user: AuthUser?) {
        statusSubject.send(user == nil ? .disconnected : .upToDate)
    }

    private func handleMemoEvent(_ event: MemoUpdateType) {
        guard let userID = authService.currentUser?.id else { return }
        Task { [weak self] in
            await self?.performMemoSync(action: Self.syncAction(for: event), userID: userID)
        }
    }

    private func performMemoSync(action: MemoSyncAction, userID: String) async {
        do {
            switch action {
            case .upsert(let memoIDs):
                for memoID in memoIDs {
                    let memo = try await memoRepository.getMemoIncludingTrash(id: memoID)
                    try await memoWriter.upsert(memo, userID: userID)
                }
            case .delete(let memoIDs):
                for memoID in memoIDs {
                    try await memoWriter.delete(memoID: memoID, userID: userID)
                }
            }
        } catch {
            // 에러 매핑과 .error status 전이는 후속 단계에서 결합. 현재는 best-effort push.
        }
    }
}
