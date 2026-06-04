//
//  MemoRepositoryRouter.swift
//  NoteCard
//

import Combine
import Domain
import FirebaseFirestore
import Foundation
import Shared
import SyncInterface

/// 인증 상태에 맞춰 활성 `MemoRepository`를 갈아끼우는 래퍼.
///
/// - 비로그인: `anonymousImpl` (Core Data)에 위임.
/// - 로그인: 해당 uid로 `MemoRepositoryFirestoreImpl` 생성, 카테고리·이미지 해석은 각 resolver Router에 위임.
/// - 전환 시 활성 impl의 `memoUpdatedPublisher`를 내부 subject로 forward해 외부 구독자에게 투명.
/// - 로그인 시 익명 메모(휴지통 포함)를 Firestore로 1회 마이그레이션 (`UserDefaults` 마커로 기기+사용자별 보장).
public final class MemoRepositoryRouter: MemoRepository, @unchecked Sendable {

    private let authService: AuthService
    private let anonymousImpl: MemoRepository
    private let categoryResolver: CategoryRepository
    private let imageResolver: ImageRepository
    private let firestore: Firestore
    private let cleanupCoordinator: AnonymousMigrationCleanupCoordinator

    private let lock = NSLock()
    private var _activeImpl: MemoRepository
    private var _firestoreImpl: MemoRepositoryFirestoreImpl?
    private var _authCancellable: AnyCancellable?
    private var _publisherCancellable: AnyCancellable?
    private var _listenerErrorCancellable: AnyCancellable?
    private var _initialSyncCancellable: AnyCancellable?

    private let updatedSubject = PassthroughSubject<MemoUpdateType, Never>()
    public var memoUpdatedPublisher: AnyPublisher<MemoUpdateType, Never> {
        updatedSubject.eraseToAnyPublisher()
    }

    private let initialServerSyncSubject = CurrentValueSubject<Bool, Never>(false)
    /// 현재 활성 FirestoreImpl 의 초기 server snapshot 도착 여부. 사인아웃 시 false 로 리셋.
    public var initialServerSyncPublisher: AnyPublisher<Bool, Never> {
        initialServerSyncSubject.eraseToAnyPublisher()
    }

    public init(
        authService: AuthService,
        anonymousImpl: MemoRepository,
        categoryResolver: CategoryRepository,
        imageResolver: ImageRepository,
        cleanupCoordinator: AnonymousMigrationCleanupCoordinator,
        firestore: Firestore = .firestore()
    ) {
        self.authService = authService
        self.anonymousImpl = anonymousImpl
        self.categoryResolver = categoryResolver
        self.imageResolver = imageResolver
        self.cleanupCoordinator = cleanupCoordinator
        self.firestore = firestore
        self._activeImpl = anonymousImpl
        attachForwarding(from: anonymousImpl)
        _authCancellable = authService.authStatePublisher.sink { [weak self] user in
            self?.handleAuthChange(user: user)
        }
    }

    private func handleAuthChange(user: AuthUser?) {
        if let userID = user?.id {
            let impl = MemoRepositoryFirestoreImpl(
                userID: userID,
                categoryResolver: categoryResolver,
                imageResolver: imageResolver,
                firestore: firestore
            )
            lock.lock()
            _firestoreImpl = impl
            _activeImpl = impl
            lock.unlock()
            attachForwarding(from: impl)
            attachListenerErrorHandling(from: impl)
            attachInitialSyncForwarding(from: impl)
            triggerMigrationIfNeeded(to: impl, userID: userID)
        } else {
            lock.lock()
            _firestoreImpl = nil
            _activeImpl = anonymousImpl
            _listenerErrorCancellable?.cancel()
            _listenerErrorCancellable = nil
            _initialSyncCancellable?.cancel()
            _initialSyncCancellable = nil
            lock.unlock()
            attachForwarding(from: anonymousImpl)
            initialServerSyncSubject.send(false)
        }
        // 백엔드 전환을 UI에 알려 재조회 유도.
        updatedSubject.send(.update(content: .titleText(memoIDs: [])))
    }

    private func attachInitialSyncForwarding(from impl: MemoRepositoryFirestoreImpl) {
        let newCancellable = impl.initialServerSyncPublisher.sink { [weak self] synced in
            self?.initialServerSyncSubject.send(synced)
        }
        lock.lock()
        _initialSyncCancellable?.cancel()
        _initialSyncCancellable = newCancellable
        lock.unlock()
    }

    /// Firestore listener 가 permission denied 등으로 발화하면 — 보통 다른 기기에서 본 계정이
    /// 삭제됐다는 신호 — 강제 로그아웃해서 익명 모드로 전환.
    private func attachListenerErrorHandling(from impl: MemoRepositoryFirestoreImpl) {
        let newCancellable = impl.listenerErrorPublisher.sink { [weak self] error in
            guard let self else { return }
            let nsError = error as NSError
            guard nsError.domain == FirestoreErrorDomain,
                  nsError.code == FirestoreErrorCode.permissionDenied.rawValue
            else { return }
            Task { [authService = self.authService] in
                try? await authService.signOut()
            }
        }
        lock.lock()
        _listenerErrorCancellable?.cancel()
        _listenerErrorCancellable = newCancellable
        lock.unlock()
    }

    /// AccountDetail 재시도 버튼 등 외부에서 마이그레이션을 수동으로 다시 시작할 때 호출.
    /// marker 이미 set 이면 short-circuit. 현재 활성 Firestore impl 이 없으면 no-op.
    public func retryMigrationIfNeeded(userID: String) {
        lock.lock()
        let impl = _firestoreImpl
        lock.unlock()
        guard let impl else { return }
        triggerMigrationIfNeeded(to: impl, userID: userID)
    }

    /// 익명 메모(휴지통 포함)를 새 Firestore impl로 이관. UserDefaults 마커로 기기+사용자별 1회.
    private func triggerMigrationIfNeeded(to firestoreImpl: MemoRepositoryFirestoreImpl, userID: String) {
        let markerKey = "sync.anonymousToFirestoreMemoMigration.\(userID)"
        let coordinator = cleanupCoordinator
        if UserDefaults.standard.bool(forKey: markerKey) {
            Task { await coordinator.reportMigrationCompleted(userID: userID) }
            return
        }
        let source = anonymousImpl
        Task { [weak firestoreImpl] in
            guard let firestoreImpl else { return }
            do {
                let active = try await source.getAllMemos()
                let trashed = try await source.getAllMemosInTrash()
                let all = active + trashed
                if !all.isEmpty {
                    try await firestoreImpl.importMemos(all)
                }
                UserDefaults.standard.set(true, forKey: markerKey)
                await coordinator.reportMigrationCompleted(userID: userID)
            } catch {
                print("[MemoRepositoryRouter] migration error: \(error)")
            }
        }
    }

    private func attachForwarding(from impl: MemoRepository) {
        let newCancellable = impl.memoUpdatedPublisher.sink { [weak self] event in
            self?.updatedSubject.send(event)
        }
        lock.lock()
        _publisherCancellable?.cancel()
        _publisherCancellable = newCancellable
        lock.unlock()
    }

    private var current: MemoRepository {
        lock.lock()
        defer { lock.unlock() }
        return _activeImpl
    }

    // MARK: - MemoRepository forwarding

    public func createNewMemo() async throws -> Memo {
        try await current.createNewMemo()
    }

    public func getMemo(id: UUID) async throws -> Memo {
        try await current.getMemo(id: id)
    }

    public func getMemoIncludingTrash(id: UUID) async throws -> Memo {
        try await current.getMemoIncludingTrash(id: id)
    }

    public func getAllMemos() async throws -> [Memo] {
        try await current.getAllMemos()
    }

    public func getAllMemos(inCategory category: Domain.Category?) async throws -> [Memo] {
        try await current.getAllMemos(inCategory: category)
    }

    public func getAllMemosInTrash() async throws -> [Memo] {
        try await current.getAllMemosInTrash()
    }

    public func searchMemo(searchText: String, inCategory category: Domain.Category?) async throws -> [Memo] {
        try await current.searchMemo(searchText: searchText, inCategory: category)
    }

    public func getFavoriteMemos() async throws -> [Memo] {
        try await current.getFavoriteMemos()
    }

    public func moveToTrash(_ memo: Memo) async throws { try await current.moveToTrash(memo) }
    public func moveToTrash(_ memos: [Memo]) async throws { try await current.moveToTrash(memos) }
    public func deleteMemo(_ memo: Memo) async throws { try await current.deleteMemo(memo) }
    public func deleteMemos(_ memos: [Memo]) async throws { try await current.deleteMemos(memos) }
    public func restore(_ memo: Memo) async throws { try await current.restore(memo) }
    public func restore(_ memos: [Memo]) async throws { try await current.restore(memos) }

    public func replaceCategories(to memo: Memo, newCategories: Set<Domain.Category>) async throws {
        try await current.replaceCategories(to: memo, newCategories: newCategories)
    }
    public func replaceCategories(to memos: [Memo], newCategories: Set<Domain.Category>) async throws {
        try await current.replaceCategories(to: memos, newCategories: newCategories)
    }
    public func addCategories(to memo: Memo, newCategories: Set<Domain.Category>) async throws {
        try await current.addCategories(to: memo, newCategories: newCategories)
    }
    public func addCategories(to memos: [Memo], newCategories: Set<Domain.Category>) async throws {
        try await current.addCategories(to: memos, newCategories: newCategories)
    }
    public func removeCategories(to memo: Memo, newCategories: Set<Domain.Category>) async throws {
        try await current.removeCategories(to: memo, newCategories: newCategories)
    }
    public func removeCategories(to memos: [Memo], newCategories: Set<Domain.Category>) async throws {
        try await current.removeCategories(to: memos, newCategories: newCategories)
    }

    public func setFavorite(_ memo: Memo, to value: Bool) async throws {
        try await current.setFavorite(memo, to: value)
    }
    public func setFavorite(_ memos: [Memo], to value: Bool) async throws {
        try await current.setFavorite(memos, to: value)
    }
    public func updateMemoContent(_ memo: Memo, newTitle: String?, newMemoText: String?) async throws {
        try await current.updateMemoContent(memo, newTitle: newTitle, newMemoText: newMemoText)
    }
}
