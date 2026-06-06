//
//  MemoRepositoryFirestoreImpl.swift
//  NoteCard
//

import Combine
import Data
import Domain
import FirebaseFirestore
import Foundation
import Shared

/// 한 사용자(`userID`)의 메모를 Firestore에서 읽고 쓰는 Repository.
///
/// 동작:
/// - 생성 시 `users/<uid>/memos` 컬렉션에 `addSnapshotListener`를 건다.
/// - 스냅샷은 **DTO 자체**를 in-memory에 보관(`snapshotDTOByID`)하고, 메서드 read 시점에
///   `categoryResolver`로 카테고리를 동적으로 해석한다 — 카테고리 이름 변경 등이 자동 반영됨.
/// - 쓰기는 SDK가 캐시 즉시 반영 + 서버 큐잉.
///
/// 미동기 항목(본 단계 외):
/// - 이미지 바이너리 (`Memo.images`는 Firestore DTO에 포함되지 않음 — 후속 이미지 Repository에서)
/// - 카테고리 modificationDate 갱신 부수효과 (categoryResolver의 책임으로 위임 가능 / 후속)
public final class MemoRepositoryFirestoreImpl: MemoRepository, @unchecked Sendable {

    private let firestore: Firestore
    private let userID: String
    private let categoryResolver: CategoryRepository
    private let imageResolver: ImageRepository

    private let memoUpdatedSubject = PassthroughSubject<MemoUpdateType, Never>()
    public var memoUpdatedPublisher: AnyPublisher<MemoUpdateType, Never> {
        memoUpdatedSubject.eraseToAnyPublisher()
    }

    /// listener 발화 시 도착한 에러를 그대로 emit. Router 가 받아 permission denied 등 세션 무효화
    /// 신호를 처리하는 데 사용.
    private let listenerErrorSubject = PassthroughSubject<Error, Never>()
    public var listenerErrorPublisher: AnyPublisher<Error, Never> {
        listenerErrorSubject.eraseToAnyPublisher()
    }

    /// listener 가 첫 snapshot 을 받으면 true 로 전이. readiness gate 신호.
    /// cache / server 어느 source 든 인정 — re-sign-in 직후엔 SDK 가 cache 만 발화하고 server fetch 를 생략하는 경우가 있음.
    /// cache emission 인 경우 home 은 stale 데이터로 빠르게 진입하고, 후속 server snapshot 도착 시 memoUpdatedPublisher 가 fire 돼 자동 refetch 됨.
    private let initialServerSyncSubject = CurrentValueSubject<Bool, Never>(false)
    public var initialServerSyncPublisher: AnyPublisher<Bool, Never> {
        initialServerSyncSubject.eraseToAnyPublisher()
    }

    /// listener가 채우는 in-memory DTO 스냅샷. 카테고리는 read 시점에 해석.
    private let snapshotLock = NSLock()
    private var snapshotDTOByID: [UUID: FirestoreMemo] = [:]
    private var listenerRegistration: ListenerRegistration?

    /// 사용자가 설정 화면에서 고른 정렬 기준. Core Data impl 과 동일한 UserDefaults 키를 공유해
    /// 두 backend 동작이 일치하도록 함.
    @UserDefault<String>(key: .orderCriterion, defaultValue: OrderCriterion.modificationDate.rawValue)
    private var orderCriterion: String

    @UserDefault<Bool>(key: .isOrderAscending, defaultValue: false)
    private var isOrderAscending: Bool

    public init(
        userID: String,
        categoryResolver: CategoryRepository,
        imageResolver: ImageRepository,
        firestore: Firestore = .firestore()
    ) {
        self.userID = userID
        self.categoryResolver = categoryResolver
        self.imageResolver = imageResolver
        self.firestore = firestore
        startListening()
    }

    deinit {
        listenerRegistration?.remove()
    }

    private var collection: CollectionReference {
        firestore.collection("users").document(userID).collection("memos")
    }

    // MARK: - Listener

    private func startListening() {
        listenerRegistration = collection.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error {
                print("[MemoRepoFirestore] listener error: \(error)")
                self.listenerErrorSubject.send(error)
                return
            }
            guard let snapshot else { return }
            if !self.initialServerSyncSubject.value {
                self.initialServerSyncSubject.send(true)
            }
            self.handleSnapshot(snapshot)
        }
    }

    private func handleSnapshot(_ snapshot: QuerySnapshot) {
        var createdIDs: [UUID] = []
        var trashedIDs: [UUID] = []
        var restoredIDs: [UUID] = []
        var updatedIDs: [UUID] = []
        var deletedIDs: [UUID] = []

        snapshotLock.lock()
        for change in snapshot.documentChanges {
            guard
                let dto = try? change.document.data(as: FirestoreMemo.self),
                let id = UUID(uuidString: dto.memoID)
            else { continue }

            switch change.type {
            case .added:
                snapshotDTOByID[id] = dto
                if dto.isInTrash {
                    // 휴지통 상태로 처음 등장(주로 listener 첫 스냅샷에서 기존 휴지통 메모 로드)
                    trashedIDs.append(id)
                } else {
                    createdIDs.append(id)
                }
            case .modified:
                let previous = snapshotDTOByID[id]
                snapshotDTOByID[id] = dto
                if let previous {
                    if !previous.isInTrash && dto.isInTrash {
                        trashedIDs.append(id)
                    } else if previous.isInTrash && !dto.isInTrash {
                        restoredIDs.append(id)
                    } else if previous != dto {
                        // Firestore listener는 로컬 write에 캐시·서버 두 번 발화 — 동일 페이로드면 emit 안 함.
                        updatedIDs.append(id)
                    }
                } else {
                    updatedIDs.append(id)
                }
            case .removed:
                snapshotDTOByID.removeValue(forKey: id)
                deletedIDs.append(id)
                if let url = try? ImageFileHandler.getDirectory(for: id) {
                    try? FileManager.default.removeItem(at: url)
                }
            }
        }
        snapshotLock.unlock()

        // 변경 종류별로 한 번씩 emit (UI는 디바운스 후 재조회하므로 coarse로 충분).
        if !createdIDs.isEmpty { memoUpdatedSubject.send(.create(memoIDs: createdIDs)) }
        if !trashedIDs.isEmpty { memoUpdatedSubject.send(.trash(memoIDs: trashedIDs)) }
        if !restoredIDs.isEmpty { memoUpdatedSubject.send(.restore(memoIDs: restoredIDs)) }
        if !updatedIDs.isEmpty {
            // 내용 변화의 종류(title/text/favorite/category 등)를 documentChanges로 확정하기 어려워
            // 가장 일반적인 .titleText로 coarse하게 emit. (UI는 IDs를 보지 않고 재조회.)
            memoUpdatedSubject.send(.update(content: .titleText(memoIDs: updatedIDs)))
        }
        if !deletedIDs.isEmpty { memoUpdatedSubject.send(.delete(memoIDs: deletedIDs)) }
    }

    // MARK: - Lock 격리 (NSLock은 async 컨텍스트에서 직접 사용 불가)

    private func cachedDTO(id: UUID) -> FirestoreMemo? {
        snapshotLock.lock()
        defer { snapshotLock.unlock() }
        return snapshotDTOByID[id]
    }

    private func allSnapshotDTOs() -> [FirestoreMemo] {
        snapshotLock.lock()
        defer { snapshotLock.unlock() }
        return Array(snapshotDTOByID.values)
    }

    // MARK: - Read

    public func getMemo(id: UUID) async throws -> Memo {
        guard let dto = cachedDTO(id: id), !dto.isInTrash else {
            throw RepositoryError.notFound
        }
        return try await resolve(dto)
    }

    public func getMemoIncludingTrash(id: UUID) async throws -> Memo {
        guard let dto = cachedDTO(id: id) else {
            throw RepositoryError.notFound
        }
        return try await resolve(dto)
    }

    public func getAllMemos() async throws -> [Memo] {
        let dtos = allSnapshotDTOs().filter { !$0.isInTrash }
        let memos = try await resolveAll(dtos)
        return sortByPreference(memos)
    }

    public func getAllMemos(inCategory category: Domain.Category?) async throws -> [Memo] {
        let dtos = allSnapshotDTOs().filter { dto in
            guard !dto.isInTrash else { return false }
            if let category {
                return dto.categoryIDs.contains(category.id.uuidString)
            } else {
                return dto.categoryIDs.isEmpty
            }
        }
        let memos = try await resolveAll(dtos)
        return sortByPreference(memos)
    }

    public func getAllMemosInTrash() async throws -> [Memo] {
        let dtos = allSnapshotDTOs().filter { $0.isInTrash }
        let memos = try await resolveAll(dtos)
        return sortByPreference(memos)
    }

    public func searchMemo(searchText: String, inCategory category: Domain.Category?) async throws -> [Memo] {
        guard !searchText.isEmpty else { return [] }
        // 클라이언트 필터링 (Firestore는 substring 쿼리 불가).
        let dtos = allSnapshotDTOs().filter { dto in
            guard !dto.isInTrash else { return false }
            if let category, !dto.categoryIDs.contains(category.id.uuidString) { return false }
            let hit = dto.memoTitle.localizedCaseInsensitiveContains(searchText)
                || dto.memoText.localizedCaseInsensitiveContains(searchText)
            return hit
        }
        let memos = try await resolveAll(dtos)
        return sortByPreference(memos)
    }

    public func getFavoriteMemos() async throws -> [Memo] {
        let dtos = allSnapshotDTOs().filter { $0.isFavorite && !$0.isInTrash }
        let memos = try await resolveAll(dtos)
        return sortByPreference(memos)
    }

    // MARK: - Create

    public func createNewMemo() async throws -> Memo {
        let now = Date()
        let memo = Memo(
            memoID: UUID(),
            creationDate: now,
            modificationDate: now,
            deletedDate: nil,
            isFavorite: false,
            isInTrash: false,
            memoText: "",
            memoTitle: "",
            categories: [],
            images: []
        )
        try await write(memo)
        return memo
        // listener .added → publisher emit, 호출자 별도 emit 불필요.
    }

    // MARK: - Soft delete (trash)

    public func moveToTrash(_ memo: Memo) async throws {
        try await collection.document(memo.memoID.uuidString).updateData(Self.trashPayload(now: Date()))
    }

    public func moveToTrash(_ memos: [Memo]) async throws {
        let batch = firestore.batch()
        let payload = Self.trashPayload(now: Date())
        for memo in memos {
            batch.updateData(payload, forDocument: collection.document(memo.memoID.uuidString))
        }
        try await batch.commit()
    }

    private static func trashPayload(now: Date) -> [String: Any] {
        [
            "isInTrash": true,
            "isFavorite": false,
            "deletedDate": Timestamp(date: now),
            "categoryIDs": [String](),
            "modificationDate": Timestamp(date: now),
            "serverUpdatedAt": FieldValue.serverTimestamp()
        ]
    }

    // MARK: - Hard delete

    public func deleteMemo(_ memo: Memo) async throws {
        try await deleteImages(of: memo)
        try await collection.document(memo.memoID.uuidString).delete()
    }

    public func deleteMemos(_ memos: [Memo]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for memo in memos {
                group.addTask { try await self.deleteImages(of: memo) }
            }
            try await group.waitForAll()
        }
        let batch = firestore.batch()
        for memo in memos {
            batch.deleteDocument(collection.document(memo.memoID.uuidString))
        }
        try await batch.commit()
    }

    /// Firestore parent doc 삭제는 sub-collection 을 자동 정리하지 않으므로 명시 순회.
    private func deleteImages(of memo: Memo) async throws {
        let images = (try? await imageResolver.getAllImageInfo(for: memo)) ?? []
        guard !images.isEmpty else { return }
        try await withThrowingTaskGroup(of: Void.self) { group in
            for image in images {
                group.addTask { try? await self.imageResolver.deleteImage(image) }
            }
            try await group.waitForAll()
        }
    }

    // MARK: - Restore

    public func restore(_ memo: Memo) async throws {
        try await collection.document(memo.memoID.uuidString).updateData(Self.restorePayload(now: Date()))
    }

    public func restore(_ memos: [Memo]) async throws {
        let batch = firestore.batch()
        let payload = Self.restorePayload(now: Date())
        for memo in memos {
            batch.updateData(payload, forDocument: collection.document(memo.memoID.uuidString))
        }
        try await batch.commit()
    }

    private static func restorePayload(now: Date) -> [String: Any] {
        [
            "isInTrash": false,
            "deletedDate": FieldValue.delete(),
            "modificationDate": Timestamp(date: now),
            "serverUpdatedAt": FieldValue.serverTimestamp()
        ]
    }

    // MARK: - Update: categories

    public func replaceCategories(to memo: Memo, newCategories: Set<Domain.Category>) async throws {
        try await collection.document(memo.memoID.uuidString).updateData([
            "categoryIDs": newCategories.map(\.id.uuidString).sorted(),
            "modificationDate": Timestamp(date: Date()),
            "serverUpdatedAt": FieldValue.serverTimestamp()
        ])
        // NOTE: 기존 Core Data 구현은 영향받은 카테고리들의 modificationDate도 갱신. 본 PR에선 생략 (후속).
    }

    public func replaceCategories(to memos: [Memo], newCategories: Set<Domain.Category>) async throws {
        let batch = firestore.batch()
        let ids = newCategories.map(\.id.uuidString).sorted()
        let now = Date()
        for memo in memos {
            batch.updateData([
                "categoryIDs": ids,
                "modificationDate": Timestamp(date: now),
                "serverUpdatedAt": FieldValue.serverTimestamp()
            ], forDocument: collection.document(memo.memoID.uuidString))
        }
        try await batch.commit()
    }

    public func addCategories(to memo: Memo, newCategories: Set<Domain.Category>) async throws {
        try await collection.document(memo.memoID.uuidString).updateData([
            "categoryIDs": FieldValue.arrayUnion(newCategories.map(\.id.uuidString)),
            "modificationDate": Timestamp(date: Date()),
            "serverUpdatedAt": FieldValue.serverTimestamp()
        ])
    }

    public func addCategories(to memos: [Memo], newCategories: Set<Domain.Category>) async throws {
        let batch = firestore.batch()
        let ids = newCategories.map(\.id.uuidString)
        let now = Date()
        for memo in memos {
            batch.updateData([
                "categoryIDs": FieldValue.arrayUnion(ids),
                "modificationDate": Timestamp(date: now),
                "serverUpdatedAt": FieldValue.serverTimestamp()
            ], forDocument: collection.document(memo.memoID.uuidString))
        }
        try await batch.commit()
    }

    public func removeCategories(to memo: Memo, newCategories: Set<Domain.Category>) async throws {
        try await collection.document(memo.memoID.uuidString).updateData([
            "categoryIDs": FieldValue.arrayRemove(newCategories.map(\.id.uuidString)),
            "modificationDate": Timestamp(date: Date()),
            "serverUpdatedAt": FieldValue.serverTimestamp()
        ])
    }

    public func removeCategories(to memos: [Memo], newCategories: Set<Domain.Category>) async throws {
        let batch = firestore.batch()
        let ids = newCategories.map(\.id.uuidString)
        let now = Date()
        for memo in memos {
            batch.updateData([
                "categoryIDs": FieldValue.arrayRemove(ids),
                "modificationDate": Timestamp(date: now),
                "serverUpdatedAt": FieldValue.serverTimestamp()
            ], forDocument: collection.document(memo.memoID.uuidString))
        }
        try await batch.commit()
    }

    // MARK: - Update: favorite / content

    public func setFavorite(_ memo: Memo, to value: Bool) async throws {
        try await collection.document(memo.memoID.uuidString).updateData([
            "isFavorite": value,
            "serverUpdatedAt": FieldValue.serverTimestamp()
        ])
    }

    public func setFavorite(_ memos: [Memo], to value: Bool) async throws {
        let batch = firestore.batch()
        for memo in memos {
            batch.updateData([
                "isFavorite": value,
                "serverUpdatedAt": FieldValue.serverTimestamp()
            ], forDocument: collection.document(memo.memoID.uuidString))
        }
        try await batch.commit()
    }

    public func updateMemoContent(_ memo: Memo, newTitle: String?, newMemoText: String?) async throws {
        var payload: [String: Any] = [
            "modificationDate": Timestamp(date: Date()),
            "serverUpdatedAt": FieldValue.serverTimestamp()
        ]
        if let newTitle { payload["memoTitle"] = newTitle }
        if let newMemoText { payload["memoText"] = newMemoText }
        try await collection.document(memo.memoID.uuidString).updateData(payload)
    }

    // MARK: - Migration

    /// 외부 소스(예: 익명 Core Data)에서 받은 메모들을 dup-check 없이 Firestore에 import.
    /// 문서 ID는 `memo.memoID.uuidString` — 같은 ID가 있으면 overwrite(멱등).
    /// 카테고리 본문은 별도 컬렉션이라 본 메서드는 `categoryIDs`만 보존하며,
    /// 이미지 바이너리는 본 단계 미동기(후속 이미지 Repository에서).
    func importMemos(_ memos: [Memo]) async throws {
        for memo in memos {
            try await write(memo)
        }
    }

    // MARK: - Helpers

    /// Memo → FirestoreMemo 페이로드로 직렬화해 `setData(merge: true)`. merge면 doc 미존재 시 upsert,
    /// 다른 기기가 추가한 필드는 보존하고, `FieldValue.delete()` 같은 sentinel도 그대로 동작.
    private func write(_ memo: Memo) async throws {
        var payload = try Firestore.Encoder().encode(FirestoreMemo(memo))
        payload["serverUpdatedAt"] = FieldValue.serverTimestamp()
        if memo.deletedDate == nil {
            // FirestoreMemo.deletedDate가 Optional이라 nil이면 인코더가 키를 생략 →
            // merge가 서버 기존 값을 보존하므로, 휴지통에서 복원된 메모는 명시적 제거 sentinel로 비워준다.
            payload["deletedDate"] = FieldValue.delete()
        }
        try await collection.document(memo.memoID.uuidString).setData(payload, merge: true)
    }

    /// 단일 DTO를 Memo로 해석 — 카테고리 본문 + 이미지 목록을 함께 채움.
    /// 이미지는 sub-collection 쿼리(SDK 자동 캐시)라 매번 네트워크 호출은 아님.
    private func resolve(_ dto: FirestoreMemo) async throws -> Memo {
        let categories = await resolveCategories(for: dto)
        guard var memo = dto.toDomain(categories: categories) else {
            throw RepositoryError.notFound
        }
        if let images = try? await imageResolver.getAllImageInfo(for: memo) {
            memo.images = Set(images)
        }
        return memo
    }

    /// 여러 DTO를 Memo로 해석 — `TaskGroup`으로 병렬 처리해 cold cache에서도 첫 로드 latency 최소화.
    /// 카테고리·이미지 해석이 dto별로 독립이고, categoryResolver(메모리 스냅샷)·imageResolver(SDK 캐시 쿼리)
    /// 둘 다 thread-safe라 안전.
    private func resolveAll(_ dtos: [FirestoreMemo]) async throws -> [Memo] {
        try await withThrowingTaskGroup(of: Memo?.self) { group in
            for dto in dtos {
                group.addTask { [self] in
                    try? await self.resolve(dto)
                }
            }
            var memos: [Memo] = []
            memos.reserveCapacity(dtos.count)
            for try await memo in group {
                if let memo { memos.append(memo) }
            }
            return memos
        }
    }

    private func resolveCategories(for dto: FirestoreMemo) async -> Set<Domain.Category> {
        var categories: Set<Domain.Category> = []
        for uuid in dto.categoryUUIDs {
            if let resolved = try? await categoryResolver.getCategory(id: uuid) {
                categories.insert(resolved)
            }
        }
        return categories
    }

    /// 사용자 설정 (UserDefaults) 의 orderCriterion / isOrderAscending 을 반영해 정렬.
    /// Core Data impl 의 NSSortDescriptor(key:ascending:) 와 동일한 결과를 내도록 맞춤.
    private func sortByPreference(_ memos: [Memo]) -> [Memo] {
        let criterion = OrderCriterion(rawValue: orderCriterion) ?? .modificationDate
        let ascending = isOrderAscending
        switch criterion {
        case .modificationDate:
            return memos.sorted {
                ascending ? $0.modificationDate < $1.modificationDate : $0.modificationDate > $1.modificationDate
            }
        case .creationDate:
            return memos.sorted {
                ascending ? $0.creationDate < $1.creationDate : $0.creationDate > $1.creationDate
            }
        }
    }
}
