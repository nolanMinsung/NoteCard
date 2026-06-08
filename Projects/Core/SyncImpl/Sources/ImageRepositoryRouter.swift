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
public final class ImageRepositoryRouter: ImageRepository, PendingUploadResumeTrigger, UploadProgressObservable, @unchecked Sendable {

    private let authService: AuthService
    private let anonymousImpl: ImageRepository
    private let anonymousMemoRepository: MemoRepository
    private let firestore: Firestore
    private let storage: Storage
    private let cleanupCoordinator: AnonymousMigrationCleanupCoordinator

    private let lock = NSLock()
    private var _activeImpl: ImageRepository
    private var _firestoreImpl: ImageRepositoryFirestoreImpl?
    private var _progressStore: ImageUploadProgressStore?
    private var _currentUserID: String?
    private var _isMigrationInFlight: Bool = false
    private var _authCancellable: AnyCancellable?
    private var _publisherCancellable: AnyCancellable?
    private var _progressForwardCancellable: AnyCancellable?

    private let updatedSubject = PassthroughSubject<ImageUpdateType, Never>()
    public var imageUpdatedPublisher: AnyPublisher<ImageUpdateType, Never> {
        updatedSubject.eraseToAnyPublisher()
    }

    private let imageUploadProgressSubject = CurrentValueSubject<UploadProgressSnapshot?, Never>(nil)
    public var imageUploadProgressPublisher: AnyPublisher<UploadProgressSnapshot?, Never> {
        imageUploadProgressSubject.eraseToAnyPublisher()
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
            let progressStore = ImageUploadProgressStore(userID: userID)
            let impl = ImageRepositoryFirestoreImpl(
                userID: userID,
                firestore: firestore,
                storage: storage,
                progressStore: progressStore
            )
            let progressForwardCancellable = progressStore.progressPublisher
                .sink { [imageUploadProgressSubject] snapshot in
                    imageUploadProgressSubject.send(snapshot)
                }
            lock.withLock {
                _progressStore = progressStore
                _firestoreImpl = impl
                _activeImpl = impl
                _currentUserID = userID
                _progressForwardCancellable?.cancel()
                _progressForwardCancellable = progressForwardCancellable
            }
            attachForwarding(from: impl)
            triggerMigrationIfNeeded(to: impl, userID: userID)
        } else {
            lock.withLock {
                _firestoreImpl = nil
                _progressStore = nil
                _activeImpl = anonymousImpl
                _currentUserID = nil
                _progressForwardCancellable?.cancel()
                _progressForwardCancellable = nil
            }
            attachForwarding(from: anonymousImpl)
            imageUploadProgressSubject.send(nil)
        }
    }

    /// 현재 sign-in 사용자가 있으면 미완료 이미지 바이너리 업로드를 재개. 진행 중이면 no-op.
    /// `sceneDidBecomeActive` 등 app lifecycle 시점에서 호출.
    public func resumePendingUploadsIfNeeded() {
        lock.lock()
        let impl = _firestoreImpl
        let userID = _currentUserID
        lock.unlock()
        guard let impl, let userID else { return }
        triggerMigrationIfNeeded(to: impl, userID: userID)
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

    /// 익명 이미지 메타데이터를 Firestore 로 이관 + 바이너리를 Storage 로 업로드.
    /// 메타 업로드 완료 시점에 marker set + cleanupCoordinator 보고 — readiness gate 통과 신호.
    /// 바이너리 업로드는 분리된 백그라운드 Task — readiness gate 와 무관.
    ///
    /// 재진입 동작:
    /// - 메타 미완 → 익명 enumerate 결과로 target 영속화 + 메타 업로드 + 바이너리 업로드 진행.
    /// - 메타 완료, 영속화된 target 있음 → 그 target 으로 바이너리 단계만 재개 (Firestore 에서
    ///   다시 enumerate 하지 않음 — sign-in 이후 새로 만든 이미지가 분모에 섞이는 걸 막기 위해).
    /// - 메타 완료, 영속화된 target 없음 → 마이그레이션 이미 끝났다는 의미 → short-circuit.
    private func triggerMigrationIfNeeded(to firestoreImpl: ImageRepositoryFirestoreImpl, userID: String) {
        let metaMarkerKey = Self.metaMarkerKey(for: userID)
        let legacyMarkerKey = Self.legacyMarkerKey(for: userID)
        let isImageMetaDataMigrated = UserDefaults.standard.bool(forKey: metaMarkerKey)
            || UserDefaults.standard.bool(forKey: legacyMarkerKey)

        let canProceed: Bool = lock.withLock {
            guard !_isMigrationInFlight else { return false }
            _isMigrationInFlight = true
            return true
        }
        guard canProceed else { return }
        let progressStore = lock.withLock { _progressStore }

        Task { [
            cleanupCoordinator,
            anonymousMemoRepository,
            anonymousImpl,
            weak firestoreImpl,
            weak self
        ] in
            defer {
                if let self {
                    self.lock.withLock { self._isMigrationInFlight = false }
                }
            }
            guard let firestoreImpl else { return }
            do {
                let imageInfosToUpload: [MemoImageInfo]
                if isImageMetaDataMigrated {
                    let storedTarget = progressStore?.currentTarget ?? []
                    if storedTarget.isEmpty {
                        // 메타도 끝났고 영속화된 target 도 없음 → 마이그레이션 이미 완료. cleanup 만 보고.
                        await cleanupCoordinator.reportMigrationCompleted(userID: userID)
                        return
                    }
                    imageInfosToUpload = storedTarget
                    await cleanupCoordinator.reportMigrationCompleted(userID: userID)
                } else {
                    let activeMemos = try await anonymousMemoRepository.getAllMemos()
                    let trashedMemos = try await anonymousMemoRepository.getAllMemosInTrash()
                    var collectedImageInfos: [MemoImageInfo] = []
                    for memo in activeMemos + trashedMemos {
                        let imageInfosOfMemo = try await anonymousImpl.getAllImageInfo(for: memo)
                        collectedImageInfos.append(contentsOf: imageInfosOfMemo)
                    }
                    progressStore?.setProgressTarget(collectedImageInfos)
                    if !collectedImageInfos.isEmpty {
                        try await firestoreImpl.importImageMetadata(collectedImageInfos)
                    }
                    UserDefaults.standard.set(true, forKey: metaMarkerKey)
                    await cleanupCoordinator.reportMigrationCompleted(userID: userID)
                    imageInfosToUpload = collectedImageInfos
                }

                if !imageInfosToUpload.isEmpty {
                    try await firestoreImpl.uploadImageBinaries(imageInfosToUpload)
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
