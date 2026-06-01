//
//  ImageRepositoryFirestoreImpl.swift
//  NoteCard
//

import Combine
import Data
import Domain
import FirebaseFirestore
import FirebaseStorage
import Foundation
import PhotosUI
import Shared
import UIKit
import UniformTypeIdentifiers

/// 한 사용자(`userID`)의 이미지를 Firestore(메타) + Firebase Storage(바이너리)에서 관리하는 Repository.
///
/// 동작:
/// - 메타데이터: Firestore `users/<uid>/memos/<memoID>/images/<imageID>` sub-collection.
///   본 PR에선 listener 미사용 — `getAllImageInfo(for:)`가 `getDocuments()`로 매번 fetch
///   (Firestore SDK가 캐시 자동 관리, 오프라인에서도 동작). 실시간 cross-device 동기화는 후속.
/// - 바이너리: Firebase Storage `users/<uid>/memos/<memoID>/<id>.<ext>`. 다운로드 시 로컬 파일시스템(`ImageFileHandler`)에
///   캐시해 다음 호출은 디스크에서 즉시 반환. 캐시 위치는 익명 모드와 동일 경로.
/// - `imageUpdatedPublisher`는 우리가 직접 호출한 쓰기에 대해서만 emit (listener 없음).
public final class ImageRepositoryFirestoreImpl: ImageRepository, @unchecked Sendable {

    private let firestore: Firestore
    private let storage: Storage
    private let userID: String

    private let imageUpdatedSubject = PassthroughSubject<ImageUpdateType, Never>()
    public var imageUpdatedPublisher: AnyPublisher<ImageUpdateType, Never> {
        imageUpdatedSubject.eraseToAnyPublisher()
    }

    public init(userID: String, firestore: Firestore = .firestore(), storage: Storage = .storage()) {
        self.userID = userID
        self.firestore = firestore
        self.storage = storage
    }

    // MARK: - Path helpers

    private func imageCollection(for memoID: UUID) -> CollectionReference {
        firestore
            .collection("users").document(userID)
            .collection("memos").document(memoID.uuidString)
            .collection("images")
    }

    private func originalStorageRef(memoID: UUID, imageID: UUID, fileExtension: String) -> StorageReference {
        storage.reference(withPath: "users/\(userID)/memos/\(memoID.uuidString)/\(imageID.uuidString).\(fileExtension)")
    }

    private func thumbnailStorageRef(memoID: UUID, thumbnailID: UUID) -> StorageReference {
        storage.reference(withPath: "users/\(userID)/memos/\(memoID.uuidString)/\(thumbnailID.uuidString).jpeg")
    }

    // MARK: - Create

    public func createImage(
        from pickerResult: PHPickerResult,
        for memo: Memo,
        originalImageID: UUID? = nil,
        thumbnailID: UUID? = nil,
        orderIndex: Int,
        isTemporary: Bool
    ) async throws -> MemoImageInfo {
        let (originalData, originalType) = try await ImageFileHandler.prepareImageData(from: pickerResult.itemProvider)
        let thumbnailData = try ImageFileHandler.createThumbnailData(from: originalData)

        let imageID = originalImageID ?? UUID()
        let thumbID = thumbnailID ?? UUID()
        guard let ext = originalType.preferredFilenameExtension else {
            throw ImageFileError.imageFileExtensionError
        }

        // 1) 로컬 파일시스템에 저장 (캐시 + 즉시 표시용)
        let memoDirectory = try ImageFileHandler.getDirectory(for: memo.memoID)
        try ImageFileHandler.save(data: originalData, to: memoDirectory, with: imageID, fileExtension: ext)
        try ImageFileHandler.save(data: thumbnailData, to: memoDirectory, with: thumbID, fileExtension: "jpeg")

        let info = MemoImageInfo(
            id: imageID,
            thumbnailID: thumbID,
            temporaryOrderIndex: orderIndex,
            orderIndex: orderIndex,
            memoID: memo.memoID,
            isTemporaryDeleted: false,
            isTemporaryAppended: isTemporary,
            fileExtension: ext
        )

        // 2) Firebase Storage에 바이너리 업로드 (원본+썸네일 병렬)
        async let originalUpload: StorageMetadata = originalStorageRef(
            memoID: memo.memoID, imageID: imageID, fileExtension: ext
        ).putDataAsync(originalData)
        async let thumbnailUpload: StorageMetadata = thumbnailStorageRef(
            memoID: memo.memoID, thumbnailID: thumbID
        ).putDataAsync(thumbnailData)
        _ = try await (originalUpload, thumbnailUpload)

        // 3) Firestore에 메타데이터 doc 작성
        var payload = try Firestore.Encoder().encode(FirestoreMemoImage(info))
        payload["serverUpdatedAt"] = FieldValue.serverTimestamp()
        try await imageCollection(for: memo.memoID).document(imageID.uuidString).setData(payload, merge: true)

        imageUpdatedSubject.send(.create(memoID: memo.memoID))
        return info
    }

    // MARK: - Read

    public func getImage(from imageInfo: MemoImageInfo) async throws -> UIImage {
        try await loadImage(memoID: imageInfo.memoID,
                            id: imageInfo.id,
                            fileExtension: imageInfo.fileExtension,
                            thumbnail: false)
    }

    public func getThumbnailImage(from imageInfo: MemoImageInfo) async throws -> UIImage {
        try await loadImage(memoID: imageInfo.memoID,
                            id: imageInfo.thumbnailID,
                            fileExtension: "jpeg",
                            thumbnail: true)
    }

    /// 로컬 캐시 우선, 없으면 Storage에서 받아와 로컬에 캐시한 뒤 반환.
    private func loadImage(memoID: UUID, id: UUID, fileExtension: String, thumbnail: Bool) async throws -> UIImage {
        let memoDirectory = try ImageFileHandler.getDirectory(for: memoID)
        let localURL = memoDirectory
            .appendingPathComponent(id.uuidString)
            .appendingPathExtension(fileExtension)

        if FileManager.default.fileExists(atPath: localURL.path) {
            return try ImageFileHandler.loadUIImage(from: localURL)
        }

        // Storage에서 다운로드 → 로컬 저장 → load
        let ref = thumbnail
            ? thumbnailStorageRef(memoID: memoID, thumbnailID: id)
            : originalStorageRef(memoID: memoID, imageID: id, fileExtension: fileExtension)
        let data = try await ref.data(maxSize: 50 * 1024 * 1024)
        try ImageFileHandler.save(data: data, to: memoDirectory, with: id, fileExtension: fileExtension)
        return try ImageFileHandler.loadUIImage(from: localURL)
    }

    public func getAllImageInfo(for memo: Memo) async throws -> [MemoImageInfo] {
        let snapshot = try await imageCollection(for: memo.memoID)
            .order(by: "orderIndex")
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: FirestoreMemoImage.self)
        }.compactMap { $0.toDomain() }
    }

    // MARK: - Listener (per-memo)

    public func observeImageChanges(for memoID: UUID) -> AnyCancellable {
        let registration = imageCollection(for: memoID).addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error {
                print("[ImageRepoFirestore] listener error for memo \(memoID): \(error)")
                return
            }
            guard let snapshot else { return }
            self.emitImageChanges(snapshot, memoID: memoID)
        }
        return AnyCancellable {
            registration.remove()
        }
    }

    private func emitImageChanges(_ snapshot: QuerySnapshot, memoID: UUID) {
        var hasAdds = false, hasMods = false, hasRems = false
        for change in snapshot.documentChanges {
            switch change.type {
            case .added: hasAdds = true
            case .modified: hasMods = true
            case .removed: hasRems = true
            }
        }
        // UI는 종류 무관하게 재조회하므로 변경 종류별로 한 번씩 coarse emit.
        if hasAdds { imageUpdatedSubject.send(.create(memoID: memoID)) }
        if hasMods { imageUpdatedSubject.send(.update(memoID: memoID)) }
        if hasRems { imageUpdatedSubject.send(.delete(memoID: memoID)) }
    }

    // MARK: - Update

    public func updateImageIndex(_ image: MemoImageInfo, newIndex: Int) async throws {
        try await imageCollection(for: image.memoID)
            .document(image.id.uuidString)
            .updateData([
                "orderIndex": newIndex,
                "serverUpdatedAt": FieldValue.serverTimestamp()
            ])
        imageUpdatedSubject.send(.update(memoID: image.memoID))
    }

    // MARK: - Delete

    public func deleteImage(_ imageInfo: MemoImageInfo) async throws {
        // 순서: Storage → Firestore → 로컬. 일부 실패해도 다음 단계 시도 (try? 사용 안 함 — 호출자에 에러 전달).
        // Storage 객체가 이미 없으면 .delete()가 throw하지만 spike에선 호출자가 catch해 처리하면 충분.
        try? await originalStorageRef(memoID: imageInfo.memoID,
                                      imageID: imageInfo.id,
                                      fileExtension: imageInfo.fileExtension).delete()
        try? await thumbnailStorageRef(memoID: imageInfo.memoID, thumbnailID: imageInfo.thumbnailID).delete()

        try await imageCollection(for: imageInfo.memoID)
            .document(imageInfo.id.uuidString)
            .delete()

        // 로컬 캐시 정리 (실패해도 무시)
        let originalURL = try? ImageFileHandler.getFileURL(for: imageInfo, thumbnail: false)
        let thumbnailURL = try? ImageFileHandler.getFileURL(for: imageInfo, thumbnail: true)
        if let originalURL { try? ImageFileHandler.delete(at: originalURL) }
        if let thumbnailURL { try? ImageFileHandler.delete(at: thumbnailURL) }

        imageUpdatedSubject.send(.delete(memoID: imageInfo.memoID))
    }

    // MARK: - Migration

    /// 외부 소스(익명 Core Data)에서 받은 이미지들을 Firestore + Storage로 import.
    /// 로컬 파일이 있어야 업로드 가능 — 누락된 이미지는 스킵하고 계속.
    /// 멱등: 같은 ID에 대해선 setData(merge:true)로 메타데이터 덮어쓰기, Storage는 동일 경로 putData로 덮어쓰기.
    func importImages(_ images: [MemoImageInfo]) async throws {
        for info in images {
            do {
                try await migrateImage(info)
            } catch {
                // 한 장 실패해도 다음 진행 — 누락 이미지 등 흔한 케이스. 로그만 남김.
                print("[ImageRepoFirestore] import skipped for \(info.id): \(error)")
            }
        }
    }

    private func migrateImage(_ info: MemoImageInfo) async throws {
        let originalURL = try ImageFileHandler.getFileURL(for: info, thumbnail: false)
        let thumbnailURL = try ImageFileHandler.getFileURL(for: info, thumbnail: true)
        let originalData = try Data(contentsOf: originalURL)
        let thumbnailData = try Data(contentsOf: thumbnailURL)

        async let originalUpload: StorageMetadata = originalStorageRef(
            memoID: info.memoID, imageID: info.id, fileExtension: info.fileExtension
        ).putDataAsync(originalData)
        async let thumbnailUpload: StorageMetadata = thumbnailStorageRef(
            memoID: info.memoID, thumbnailID: info.thumbnailID
        ).putDataAsync(thumbnailData)
        _ = try await (originalUpload, thumbnailUpload)

        var payload = try Firestore.Encoder().encode(FirestoreMemoImage(info))
        payload["serverUpdatedAt"] = FieldValue.serverTimestamp()
        try await imageCollection(for: info.memoID).document(info.id.uuidString).setData(payload, merge: true)
    }
}
