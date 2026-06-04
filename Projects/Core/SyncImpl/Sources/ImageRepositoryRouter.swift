//
//  ImageRepositoryRouter.swift
//  NoteCard
//

import Combine
import Domain
import FirebaseFirestore
import FirebaseStorage
import Foundation
import PhotosUI
import Shared
import SyncInterface
import UIKit

/// 인증 상태에 맞춰 활성 `ImageRepository`를 갈아끼우는 래퍼.
///
/// - 비로그인: `anonymousImpl` (Core Data + 로컬 파일시스템)에 위임.
/// - 로그인: 해당 uid로 `ImageRepositoryFirestoreImpl` 생성, 그쪽으로 위임.
/// - 전환 시 활성 impl의 `imageUpdatedPublisher`를 내부 subject로 forward.
/// - 로그인 시 익명 이미지(전 메모 + 휴지통)를 Storage + Firestore로 1회 마이그레이션.
///   메모 마이그레이션과 병렬로 진행되므로, 익명 enumeration은 `anonymousMemoRepository`를 직접 조회.
public final class ImageRepositoryRouter: ImageRepository, @unchecked Sendable {

    private let authService: AuthService
    private let anonymousImpl: ImageRepository
    private let anonymousMemoRepository: MemoRepository
    private let firestore: Firestore
    private let storage: Storage
    private let cleanupCoordinator: AnonymousMigrationCleanupCoordinator

    private let lock = NSLock()
    private var _activeImpl: ImageRepository
    private var _firestoreImpl: ImageRepositoryFirestoreImpl?
    private var _authCancellable: AnyCancellable?
    private var _publisherCancellable: AnyCancellable?

    private let updatedSubject = PassthroughSubject<ImageUpdateType, Never>()
    public var imageUpdatedPublisher: AnyPublisher<ImageUpdateType, Never> {
        updatedSubject.eraseToAnyPublisher()
    }

    public init(
        authService: AuthService,
        anonymousImpl: ImageRepository,
        anonymousMemoRepository: MemoRepository,
        cleanupCoordinator: AnonymousMigrationCleanupCoordinator,
        firestore: Firestore = .firestore(),
        storage: Storage = .storage()
    ) {
        self.authService = authService
        self.anonymousImpl = anonymousImpl
        self.anonymousMemoRepository = anonymousMemoRepository
        self.cleanupCoordinator = cleanupCoordinator
        self.firestore = firestore
        self.storage = storage
        self._activeImpl = anonymousImpl
        attachForwarding(from: anonymousImpl)
        _authCancellable = authService.authStatePublisher.sink { [weak self] user in
            self?.handleAuthChange(user: user)
        }
    }

    private func handleAuthChange(user: AuthUser?) {
        if let userID = user?.id {
            let impl = ImageRepositoryFirestoreImpl(userID: userID, firestore: firestore, storage: storage)
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
    }

    /// 익명 이미지 메타데이터를 Firestore 로 이관. UserDefaults 마커로 기기+사용자별 1회.
    /// 메타 업로드 완료 시점에 marker set + cleanupCoordinator 보고 (= readiness gate 통과 신호).
    /// 바이너리 업로드는 분리된 백그라운드 Task — readiness gate 와 무관.
    private func triggerMigrationIfNeeded(to firestoreImpl: ImageRepositoryFirestoreImpl, userID: String) {
        let metaMarkerKey = Self.metaMarkerKey(for: userID)
        let legacyMarkerKey = Self.legacyMarkerKey(for: userID)
        let coordinator = cleanupCoordinator

        // v2.5.0 에서 set 된 통합 marker 가 있으면 메타도 완료된 것으로 인정 (호환).
        if UserDefaults.standard.bool(forKey: metaMarkerKey) || UserDefaults.standard.bool(forKey: legacyMarkerKey) {
            Task { await coordinator.reportMigrationCompleted(userID: userID) }
            return
        }
        let memoRepo = anonymousMemoRepository
        let imageRepo = anonymousImpl
        Task { [weak firestoreImpl] in
            guard let firestoreImpl else { return }
            do {
                let active = try await memoRepo.getAllMemos()
                let trashed = try await memoRepo.getAllMemosInTrash()
                var collected: [MemoImageInfo] = []
                for memo in active + trashed {
                    let images = try await imageRepo.getAllImageInfo(for: memo)
                    collected.append(contentsOf: images)
                }
                if !collected.isEmpty {
                    try await firestoreImpl.importImageMetadata(collected)
                }
                UserDefaults.standard.set(true, forKey: metaMarkerKey)
                await coordinator.reportMigrationCompleted(userID: userID)
                if !collected.isEmpty {
                    try await firestoreImpl.uploadImageBinaries(collected)
                }
            } catch {
                print("[ImageRepositoryRouter] migration error: \(error)")
            }
        }
    }

    static func metaMarkerKey(for userID: String) -> String {
        "sync.anonymousToFirestoreImageMetadataMigration.\(userID)"
    }

    static func legacyMarkerKey(for userID: String) -> String {
        "sync.anonymousToFirestoreImageMigration.\(userID)"
    }

    private func attachForwarding(from impl: ImageRepository) {
        let newCancellable = impl.imageUpdatedPublisher.sink { [weak self] event in
            self?.updatedSubject.send(event)
        }
        lock.lock()
        _publisherCancellable?.cancel()
        _publisherCancellable = newCancellable
        lock.unlock()
    }

    private var current: ImageRepository {
        lock.lock()
        defer { lock.unlock() }
        return _activeImpl
    }

    // MARK: - ImageRepository forwarding

    public func createImage(
        from pickerResult: PHPickerResult,
        for memo: Memo,
        originalImageID: UUID?,
        thumbnailID: UUID?,
        orderIndex: Int,
        isTemporary: Bool
    ) async throws -> MemoImageInfo {
        try await current.createImage(
            from: pickerResult,
            for: memo,
            originalImageID: originalImageID,
            thumbnailID: thumbnailID,
            orderIndex: orderIndex,
            isTemporary: isTemporary
        )
    }

    public func getImage(from imageInfo: MemoImageInfo) async throws -> UIImage {
        try await current.getImage(from: imageInfo)
    }

    public func getThumbnailImage(from imageInfo: MemoImageInfo) async throws -> UIImage {
        try await current.getThumbnailImage(from: imageInfo)
    }

    public func getAllImageInfo(for memo: Memo) async throws -> [MemoImageInfo] {
        try await current.getAllImageInfo(for: memo)
    }

    public func updateImageIndex(_ image: MemoImageInfo, newIndex: Int) async throws {
        try await current.updateImageIndex(image, newIndex: newIndex)
    }

    public func deleteImage(_ imageInfo: MemoImageInfo) async throws {
        try await current.deleteImage(imageInfo)
    }

    public func observeImageChanges(for memoID: UUID) -> AnyCancellable {
        current.observeImageChanges(for: memoID)
    }
}
