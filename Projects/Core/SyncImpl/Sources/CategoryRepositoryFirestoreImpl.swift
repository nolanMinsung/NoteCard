//
//  CategoryRepositoryFirestoreImpl.swift
//  NoteCard
//
//  Spike — 옵션 B 검증용 Firestore 기반 CategoryRepository.
//  목적: 실시간 listener의 UX·코드 부피·전환 안전성을 직접 느껴보기 위함.
//  정식 채택 시 위치(모듈)·에러 모델·미구현 메서드를 재설계.
//

import Combine
import Domain
import FirebaseFirestore
import Foundation
import Shared

/// 한 사용자(`userID`)의 카테고리를 Firestore에서 읽고 쓰는 Repository.
///
/// 동작:
/// - 생성 시 `users/<uid>/categories` 컬렉션에 실시간 `addSnapshotListener`를 건다.
/// - 서버/캐시에서 오는 스냅샷을 in-memory `snapshot`에 동기화하고, document 변경을
///   `categoryUpdatedPublisher`로 emit (UI가 그걸 받아 다시 fetch).
/// - 쓰기(`create`/`changeCategoryName`/`deleteCategory`)는 SDK가 캐시 즉시 반영 + 서버 큐잉.
/// - 오프라인에서도 캐시로 동작하고 온라인 복귀 시 자동 sync.
public final class CategoryRepositoryFirestoreImpl: CategoryRepository, @unchecked Sendable {

    private let firestore: Firestore
    private let userID: String

    private let categoryUpdatedSubject = PassthroughSubject<CategoryUpdateType, Never>()
    public var categoryUpdatedPublisher: AnyPublisher<CategoryUpdateType, Never> {
        categoryUpdatedSubject.eraseToAnyPublisher()
    }

    /// listener가 채우는 in-memory 스냅샷. 읽기/쓰기 모두 `snapshotLock`으로 보호.
    private let snapshotLock = NSLock()
    private var snapshotByID: [UUID: Domain.Category] = [:]
    private var listenerRegistration: ListenerRegistration?

    public init(userID: String, firestore: Firestore = .firestore()) {
        self.userID = userID
        self.firestore = firestore
        startListening()
    }

    deinit {
        listenerRegistration?.remove()
    }

    private var collection: CollectionReference {
        firestore.collection("users").document(userID).collection("categories")
    }

    // MARK: - Listener

    private func startListening() {
        listenerRegistration = collection.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error {
                // 스파이크에선 디버그 로그로만. 정식 채택 시 status로 surface.
                print("[CategoryRepoFirestore] listener error: \(error)")
                return
            }
            guard let snapshot else { return }
            self.handleSnapshot(snapshot)
        }
    }

    private func handleSnapshot(_ snapshot: QuerySnapshot) {
        var createdIDs: [UUID] = []
        var modifiedIDs: [UUID] = []
        var deletedIDs: [UUID] = []

        snapshotLock.lock()
        for change in snapshot.documentChanges {
            guard
                let dto = try? change.document.data(as: FirestoreCategory.self),
                let domain = dto.toDomain()
            else { continue }

            switch change.type {
            case .added:
                snapshotByID[domain.id] = domain
                createdIDs.append(domain.id)
            case .modified:
                snapshotByID[domain.id] = domain
                modifiedIDs.append(domain.id)
            case .removed:
                snapshotByID.removeValue(forKey: domain.id)
                deletedIDs.append(domain.id)
            }
        }
        snapshotLock.unlock()

        // 변경 종류별로 한 번씩 emit (UI는 어차피 디바운스 후 재조회하므로 충분).
        if !createdIDs.isEmpty {
            categoryUpdatedSubject.send(.create(categoryIDs: createdIDs))
        }
        if !modifiedIDs.isEmpty {
            categoryUpdatedSubject.send(.update(content: .name(categoryIDs: modifiedIDs)))
        }
        if !deletedIDs.isEmpty {
            categoryUpdatedSubject.send(.delete(categoryIDs: deletedIDs))
        }
    }

    // MARK: - Read

    public func getCategory(id: UUID) async throws -> Domain.Category {
        if let cached = cachedCategory(id: id) { return cached }
        throw FirestoreRepositoryError.notFound
    }

    public func getAllCategories(
        inOrderOf orderCriterion: CategoryProperties,
        isAscending: Bool
    ) async throws -> [Domain.Category] {
        Self.sort(allSnapshotCategories(), by: orderCriterion, ascending: isAscending)
    }

    public func getAllCategories(
        ofMemo memo: Memo,
        inOrderOf orderCriterion: CategoryProperties,
        isAscending: Bool
    ) async throws -> [Domain.Category] {
        // Memo가 들고 있는 카테고리 id로 필터. 메모 Repository가 Firestore로 옮겨갈 때 함께 점검.
        let ids = Set(memo.categories.map(\.id))
        let filtered = allSnapshotCategories().filter { ids.contains($0.id) }
        return Self.sort(filtered, by: orderCriterion, ascending: isAscending)
    }

    public func searchCategory(
        _ searchText: String,
        inOrderOf orderCriterion: CategoryProperties,
        isAscending: Bool
    ) async throws -> [Domain.Category] {
        // 클라이언트 필터링. Firestore는 substring 쿼리가 없어서 이게 정석 경로.
        let filtered = allSnapshotCategories().filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        return Self.sort(filtered, by: orderCriterion, ascending: isAscending)
    }

    public func memoCount(of category: Domain.Category) async throws -> Int {
        // Memo Repository가 Firestore로 가면 그때 count_query/denormalized count 결정.
        // 스파이크에선 0 반환 (UI는 표시만 0으로 뜸).
        0
    }

    // MARK: - Write

    public func create(name: String) async throws {
        // 같은 이름 중복 방지 (Core Data 구현과 정책 맞춤).
        let existingNames = snapshotNames()
        guard !existingNames.contains(name) else {
            throw FirestoreRepositoryError.duplicateName
        }
        let now = Date()
        let category = Domain.Category(id: UUID(), name: name, creationDate: now, modificationDate: now)
        var payload = try Firestore.Encoder().encode(FirestoreCategory(category))
        payload["serverUpdatedAt"] = FieldValue.serverTimestamp()
        try await collection.document(category.id.uuidString).setData(payload)
        // listener가 .added로 받아 publisher emit. 호출자는 별도 emit 불필요.
    }

    public func changeCategoryName(_ category: Domain.Category, newName: String) async throws {
        let existingNames = snapshotNames()
        guard !existingNames.contains(newName) else {
            throw FirestoreRepositoryError.duplicateName
        }
        try await collection.document(category.id.uuidString).updateData([
            "name": newName,
            "modificationDate": Timestamp(date: Date()),
            "serverUpdatedAt": FieldValue.serverTimestamp()
        ])
    }

    public func deleteCategory(_ category: Domain.Category) async throws {
        try await collection.document(category.id.uuidString).delete()
    }

    public func updateModificationDate(of category: Domain.Category) async throws {
        try await collection.document(category.id.uuidString).updateData([
            "modificationDate": Timestamp(date: Date()),
            "serverUpdatedAt": FieldValue.serverTimestamp()
        ])
    }

    // MARK: - Migration

    /// 외부 소스(예: 익명 Core Data)에서 받은 카테고리들을 dup-check 없이 Firestore에 import.
    /// 문서 ID는 `category.id.uuidString` — 같은 ID가 있으면 overwrite(멱등).
    /// 호출자가 "이번 사용자/기기에서 한 번만 호출" 보장하지 않으면 newer Firestore 데이터가
    /// stale 로컬 데이터로 덮어쓰여 데이터 손실 위험 있음.
    func importCategories(_ categories: [Domain.Category]) async throws {
        for category in categories {
            var payload = try Firestore.Encoder().encode(FirestoreCategory(category))
            payload["serverUpdatedAt"] = FieldValue.serverTimestamp()
            try await collection.document(category.id.uuidString).setData(payload)
        }
    }

    // MARK: - Helpers

    // 락 사용 구간을 동기 메서드로 격리한다 (NSLock은 async 컨텍스트에서 직접 사용 불가).

    private func snapshotNames() -> Set<String> {
        snapshotLock.lock()
        defer { snapshotLock.unlock() }
        return Set(snapshotByID.values.map(\.name))
    }

    private func cachedCategory(id: UUID) -> Domain.Category? {
        snapshotLock.lock()
        defer { snapshotLock.unlock() }
        return snapshotByID[id]
    }

    private func allSnapshotCategories() -> [Domain.Category] {
        snapshotLock.lock()
        defer { snapshotLock.unlock() }
        return Array(snapshotByID.values)
    }

    private static func sort(
        _ categories: [Domain.Category],
        by criterion: CategoryProperties,
        ascending: Bool
    ) -> [Domain.Category] {
        categories.sorted { lhs, rhs in
            let result: Bool
            switch criterion {
            case .name:
                result = lhs.name < rhs.name
            case .creationDate:
                result = lhs.creationDate < rhs.creationDate
            case .modificationDate:
                result = lhs.modificationDate < rhs.modificationDate
            }
            return ascending ? result : !result
        }
    }
}

/// 스파이크 전용 에러. 정식 채택 시 도메인 에러 모델과 통합.
public enum FirestoreRepositoryError: Error {
    case notFound
    case duplicateName
}
