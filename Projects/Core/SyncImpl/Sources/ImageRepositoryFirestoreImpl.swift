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
    /// 익명 → Firestore 마이그레이션의 바이너리 업로드 단계에서 한 장씩 완료 표시를 남기는 저장소.
    /// nil 이면 skip 판정·기록 모두 생략 (마이그레이션 외 경로에선 주입할 필요 없음).
    private let progressStore: ImageUploadProgressStore?

    private let imageUpdatedSubject = PassthroughSubject<ImageUpdateType, Never>()
    public var imageUpdatedPublisher: AnyPublisher<ImageUpdateType, Never> {
        imageUpdatedSubject.eraseToAnyPublisher()
    }

    init(
        userID: String,
        firestore: Firestore = .firestore(),
        storage: Storage = .storage(),
        progressStore: ImageUploadProgressStore? = nil
    ) {
        self.userID = userID
        self.firestore = firestore
        self.storage = storage
        self.progressStore = progressStore
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
        var hasAddedImages = false
        var hasModifiedImages = false
        var hasRemovedImages = false
        for change in snapshot.documentChanges {
            switch change.type {
            case .added:
                hasAddedImages = true
            case .modified:
                hasModifiedImages = true
            case .removed:
                hasRemovedImages = true
                if let dto = try? change.document.data(as: FirestoreMemoImage.self),
                   let info = dto.toDomain() {
                    deleteLocalImageFiles(for: info)
                }
            }
        }
        // UI는 종류 무관하게 재조회하므로 변경 종류별로 한 번씩 coarse emit.
        if hasAddedImages { imageUpdatedSubject.send(.create(memoID: memoID)) }
        if hasModifiedImages { imageUpdatedSubject.send(.update(memoID: memoID)) }
        if hasRemovedImages { imageUpdatedSubject.send(.delete(memoID: memoID)) }
    }

    private func deleteLocalImageFiles(for info: MemoImageInfo) {
        if let originalURL = try? ImageFileHandler.getFileURL(for: info, thumbnail: false) {
            try? ImageFileHandler.delete(at: originalURL)
        }
        if let thumbnailURL = try? ImageFileHandler.getFileURL(for: info, thumbnail: true) {
            try? ImageFileHandler.delete(at: thumbnailURL)
        }
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

    /// 익명 Core Data 의 이미지 메타데이터만 Firestore 에 import. Storage 바이너리 업로드는 별도 단계.
    /// 한 장 실패해도 다음 진행. setData(merge: true) 로 멱등.
    func importImageMetadata(_ images: [MemoImageInfo]) async throws {
        for info in images {
            do {
                var payload = try Firestore.Encoder().encode(FirestoreMemoImage(info))
                payload["serverUpdatedAt"] = FieldValue.serverTimestamp()
                try await imageCollection(for: info.memoID).document(info.id.uuidString).setData(payload, merge: true)
            } catch {
                print("[ImageRepoFirestore] meta import skipped for \(info.id): \(error)")
            }
        }
    }

    /// 익명 이미지의 원본 + 썸네일 바이너리를 Storage 로 업로드. 메타와 분리돼 사용자 readiness gate 와 무관하게
    /// 백그라운드에서 진행. putData 가 동일 path 멱등 덮어쓰기.
    ///
    /// `progressStore` 가 주입돼 있으면 시작 전 이미 완료된 variant 는 skip 하고 성공한 variant 만 mark.
    /// 같은 이미지의 원본·썸네일은 병렬 업로드 후 각각 mark — 한 쪽이 실패해도 다른 쪽 mark 가 남아
    /// 다음 시도에서 실패한 쪽만 재시도된다.
    func uploadImageBinaries(_ images: [MemoImageInfo]) async throws {
        for info in images {
            async let originalDone: Void = uploadVariantIfNeeded(.original, of: info)
            async let thumbnailDone: Void = uploadVariantIfNeeded(.thumbnail, of: info)
            _ = await (originalDone, thumbnailDone)
        }
    }

    private func uploadVariantIfNeeded(_ variant: ImageUploadProgressStore.Variant, of info: MemoImageInfo) async {
        if progressStore?.isUploaded(imageInfo: info, variant: variant) == true { return }
        do {
            switch variant {
            case .original:
                let url = try ImageFileHandler.getFileURL(for: info, thumbnail: false)
                let data = try Data(contentsOf: url)
                _ = try await originalStorageRef(
                    memoID: info.memoID, imageID: info.id, fileExtension: info.fileExtension
                ).putDataAsync(data)
            case .thumbnail:
                let url = try ImageFileHandler.getFileURL(for: info, thumbnail: true)
                let data = try Data(contentsOf: url)
                _ = try await thumbnailStorageRef(
                    memoID: info.memoID, thumbnailID: info.thumbnailID
                ).putDataAsync(data)
            }
            progressStore?.markUploaded(imageInfo: info, variant: variant)
        } catch {
            print("[ImageRepoFirestore] binary upload skipped for \(info.id) \(variant.rawValue): \(error)")
        }
    }
}
