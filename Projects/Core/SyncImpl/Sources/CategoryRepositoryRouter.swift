//
//  CategoryRepositoryRouter.swift
//  NoteCard
//
//  Spike — 옵션 B 검증용 라우터.
//  인증 상태에 따라 두 구현체(익명=CoreData / 로그인=Firestore) 사이를 스위칭한다.
//  소비자는 단일 `CategoryRepository` 참조만 들고 있어도 백엔드 전환이 투명하게 처리됨.
//

import Combine
import Domain
import FirebaseFirestore
import Foundation
import Shared
import SyncInterface

/// 인증 상태에 맞춰 활성 `CategoryRepository`를 갈아끼우는 래퍼.
///
/// - 비로그인: `anonymousImpl` (Core Data)에 위임 — 모든 데이터 기기에 머무름.
/// - 로그인: 해당 uid로 `CategoryRepositoryFirestoreImpl` 생성, 그쪽으로 위임 — 실시간 listener 동작.
/// - 전환 시 활성 impl의 `categoryUpdatedPublisher`를 내부 subject로 forward해 외부 구독자는 영향 없음.
///
/// (스파이크라 익명→Firestore 마이그레이션은 별도 단계에서. 현재는 로그인 후 Firestore가 비어 있으면
/// 홈 화면도 비어 보임.)
public final class CategoryRepositoryRouter: CategoryRepository, @unchecked Sendable {

    private let authService: AuthService
    private let anonymousImpl: CategoryRepository
    private let firestore: Firestore

    private let lock = NSLock()
    private var _activeImpl: CategoryRepository
    private var _firestoreImpl: CategoryRepositoryFirestoreImpl?
    private var _authCancellable: AnyCancellable?
    private var _publisherCancellable: AnyCancellable?
    private var _listenerErrorCancellable: AnyCancellable?

    private let updatedSubject = PassthroughSubject<CategoryUpdateType, Never>()
    public var categoryUpdatedPublisher: AnyPublisher<CategoryUpdateType, Never> {
        updatedSubject.eraseToAnyPublisher()
    }

    public init(
        authService: AuthService,
        anonymousImpl: CategoryRepository,
        firestore: Firestore = .firestore()
    ) {
        self.authService = authService
        self.anonymousImpl = anonymousImpl
        self.firestore = firestore
        self._activeImpl = anonymousImpl
        attachForwarding(from: anonymousImpl)
        // CurrentValueSubject auth publisher는 구독 즉시 현재 값을 동기 전달 → 첫 핸들링은 여기서.
        _authCancellable = authService.authStatePublisher.sink { [weak self] user in
            self?.handleAuthChange(user: user)
        }
    }

    private func handleAuthChange(user: AuthUser?) {
        if let userID = user?.id {
            // 로그인 (또는 다른 uid로 전환) — Firestore impl 생성·교체.
            let impl = CategoryRepositoryFirestoreImpl(userID: userID, firestore: firestore)
            lock.lock()
            _firestoreImpl = impl
            _activeImpl = impl
            lock.unlock()
            attachForwarding(from: impl)
            attachListenerErrorHandling(from: impl)
            // 익명 → Firestore 1회 마이그레이션 (백그라운드)
            triggerMigrationIfNeeded(to: impl, userID: userID)
        } else {
            // 로그아웃 — Firestore impl 해제, 익명으로 복귀.
            lock.lock()
            _firestoreImpl = nil
            _activeImpl = anonymousImpl
            _listenerErrorCancellable?.cancel()
            _listenerErrorCancellable = nil
            lock.unlock()
            attachForwarding(from: anonymousImpl)
        }
        // 백엔드가 바뀌었음을 UI에 알려 재조회 유도.
        // (Core Data impl은 자발적 emit이 없고, Firestore listener도 첫 스냅샷 도착이 비동기라 둘 다 보조)
        updatedSubject.send(.update(content: .name(categoryIDs: [])))
    }

    /// Firestore listener 가 permission denied 등으로 발화하면 — 다른 기기에서 본 계정이 삭제됐다는
    /// 신호일 가능성 — 강제 signOut 으로 익명 모드 복귀.
    private func attachListenerErrorHandling(from impl: CategoryRepositoryFirestoreImpl) {
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

    /// 익명 카테고리를 새 Firestore impl로 이관한다. UserDefaults 마커로 기기+사용자별 1회만 수행.
    /// (재호출 시 stale 로컬이 newer Firestore를 덮어쓰는 데이터 손실 방지)
    private func triggerMigrationIfNeeded(to firestoreImpl: CategoryRepositoryFirestoreImpl, userID: String) {
        let markerKey = "sync.anonymousToFirestoreCategoryMigration.\(userID)"
        guard !UserDefaults.standard.bool(forKey: markerKey) else { return }
        let source = anonymousImpl
        Task { [weak firestoreImpl] in
            guard let firestoreImpl else { return }
            do {
                let anonymous = try await source.getAllCategories(inOrderOf: .modificationDate, isAscending: true)
                if !anonymous.isEmpty {
                    try await firestoreImpl.importCategories(anonymous)
                }
                UserDefaults.standard.set(true, forKey: markerKey)
            } catch {
                // 스파이크에선 로그만. 정식 채택 시 status로 surface.
                print("[CategoryRepositoryRouter] migration error: \(error)")
            }
        }
    }

    /// 활성 impl의 `categoryUpdatedPublisher`를 외부 subject로 republish.
    private func attachForwarding(from impl: CategoryRepository) {
        let newCancellable = impl.categoryUpdatedPublisher.sink { [weak self] event in
            self?.updatedSubject.send(event)
        }
        lock.lock()
        _publisherCancellable?.cancel()
        _publisherCancellable = newCancellable
        lock.unlock()
    }

    private var current: CategoryRepository {
        lock.lock()
        defer { lock.unlock() }
        return _activeImpl
    }

    // MARK: - CategoryRepository forwarding

    public func create(name: String) async throws {
        try await current.create(name: name)
    }

    public func getCategory(id: UUID) async throws -> Domain.Category {
        try await current.getCategory(id: id)
    }

    public func getAllCategories(
        inOrderOf orderCriterion: CategoryProperties,
        isAscending: Bool
    ) async throws -> [Domain.Category] {
        try await current.getAllCategories(inOrderOf: orderCriterion, isAscending: isAscending)
    }

    public func getAllCategories(
        ofMemo memo: Memo,
        inOrderOf orderCriterion: CategoryProperties,
        isAscending: Bool
    ) async throws -> [Domain.Category] {
        try await current.getAllCategories(ofMemo: memo, inOrderOf: orderCriterion, isAscending: isAscending)
    }

    public func searchCategory(
        _ searchText: String,
        inOrderOf orderCriterion: CategoryProperties,
        isAscending: Bool
    ) async throws -> [Domain.Category] {
        try await current.searchCategory(searchText, inOrderOf: orderCriterion, isAscending: isAscending)
    }

    public func changeCategoryName(_ category: Domain.Category, newName: String) async throws {
        try await current.changeCategoryName(category, newName: newName)
    }

    public func deleteCategory(_ category: Domain.Category) async throws {
        try await current.deleteCategory(category)
    }

    public func memoCount(of category: Domain.Category) async throws -> Int {
        try await current.memoCount(of: category)
    }

    public func updateModificationDate(of category: Domain.Category) async throws {
        try await current.updateModificationDate(of: category)
    }
}
