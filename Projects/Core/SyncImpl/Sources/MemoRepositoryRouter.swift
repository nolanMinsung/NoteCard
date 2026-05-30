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
/// - 로그인: 해당 uid로 `MemoRepositoryFirestoreImpl` 생성, 카테고리 해석은 `categoryResolver`(보통 카테고리 Router)에 위임.
/// - 전환 시 활성 impl의 `memoUpdatedPublisher`를 내부 subject로 forward해 외부 구독자에게 투명.
/// - 로그인 시 익명 메모(휴지통 포함)를 Firestore로 1회 마이그레이션 (`UserDefaults` 마커로 기기+사용자별 보장).
public final class MemoRepositoryRouter: MemoRepository, @unchecked Sendable {

    private let authService: AuthService
    private let anonymousImpl: MemoRepository
    private let categoryResolver: CategoryRepository
    private let firestore: Firestore

    private let lock = NSLock()
    private var _activeImpl: MemoRepository
    private var _firestoreImpl: MemoRepositoryFirestoreImpl?
    private var _authCancellable: AnyCancellable?
    private var _publisherCancellable: AnyCancellable?

    private let updatedSubject = PassthroughSubject<MemoUpdateType, Never>()
    public var memoUpdatedPublisher: AnyPublisher<MemoUpdateType, Never> {
        updatedSubject.eraseToAnyPublisher()
    }

    public init(
        authService: AuthService,
        anonymousImpl: MemoRepository,
        categoryResolver: CategoryRepository,
        firestore: Firestore = .firestore()
    ) {
        self.authService = authService
        self.anonymousImpl = anonymousImpl
        self.categoryResolver = categoryResolver
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
                firestore: firestore
            )
            lock.lock()
            _firestoreImpl = impl
            _activeImpl = impl
            lock.unlock()
            attachForwarding(from: impl)
            triggerMigrationIfNeeded(to: impl, userID: userID)
        } else {
            lock.lock()
            _firestoreImpl = nil
            _activeImpl = anonymousImpl
            lock.unlock()
            attachForwarding(from: anonymousImpl)
        }
        // 백엔드 전환을 UI에 알려 재조회 유도.
        updatedSubject.send(.update(content: .titleText(memoIDs: [])))
    }

    /// 익명 메모(휴지통 포함)를 새 Firestore impl로 이관. UserDefaults 마커로 기기+사용자별 1회.
    private func triggerMigrationIfNeeded(to firestoreImpl: MemoRepositoryFirestoreImpl, userID: String) {
        let markerKey = "sync.anonymousToFirestoreMemoMigration.\(userID)"
        guard !UserDefaults.standard.bool(forKey: markerKey) else { return }
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
