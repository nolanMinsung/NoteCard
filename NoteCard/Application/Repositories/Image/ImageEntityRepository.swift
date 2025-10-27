//
//  ImageEntityRepository.swift
//  NoteCard
//
//  Created by 김민성 on 9/10/25.
//

import Combine
import CoreData
import PhotosUI
import UIKit
import UniformTypeIdentifiers

actor ImageEntityRepository: ImageRepository {
    
    enum ImageUpdateType: Equatable {
        case create(memoID: UUID)
        case delete(memoID: UUID)
        case update(memoID: UUID)
        
        var memoID: UUID {
            switch self {
            case .create(let memoID):
                return memoID
            case .delete(let memoID):
                return memoID
            case .update(let memoID):
                return memoID
            }
        }
    }
    
    static let shared = ImageEntityRepository()
    private init() { }
    
    private let context = CoreDataStack.shared.backgroundContext
    
    // MARK: - Subjects, Publisher
    
    nonisolated private let imageUpdatedSubject = PassthroughSubject<ImageUpdateType, Never>()
    nonisolated var imageUpdatedPublisher: AnyPublisher<ImageUpdateType, Never> {
        imageUpdatedSubject.eraseToAnyPublisher()
    }
    private var cancellables = Set<AnyCancellable>()
    
    func createImage(
        from pickerResult: PHPickerResult,
        for memo: Memo,
        originalImageID: UUID? = nil,
        thumbnailID: UUID? = nil,
        orderIndex: Int,
        isTemporary: Bool
    ) async throws -> MemoImageInfo {
        
        let (originalData, originalType) = try await ImageFileHandler.prepareImageData(from: pickerResult.itemProvider)
        let thumbnailData = try ImageFileHandler.createThumbnailData(from: originalData)
        
        // MemoEntity 불러오기(후에 ImageEntity에서 생성자의 매개변수로 넣기 위함)
        let memoEntity = try await MemoEntityRepository.shared.fetchMemoEntity(id: memo.memoID)
        
        let createdMemoInfo =  try await context.perform { [unowned self] in
            // 코어데이터에 저장할 데이터
            let orderIndex: Int64 = Int64(min(max(0, orderIndex), Int(Int64.max)))
            let originalImageID = originalImageID ?? UUID()
            let thumbnailID = thumbnailID ?? UUID()
            let memoDirectoryURL = try ImageFileHandler.getDirectory(for: memo.memoID)
            guard let fileExtension = originalType.preferredFilenameExtension else {
                throw ImageFileError.imageFileExtensionError
            }
            
            let newImageEntity = ImageEntity(
                uuid: originalImageID,
                thumbnailUUID: thumbnailID,
                temporaryOrderIndex: orderIndex,
                orderIndex: orderIndex,
                isTemporaryAppended: isTemporary,
                fileExtension: fileExtension,
                memo: memoEntity,
                context: self.context
            )
            
            // (트랜잭션) 파일 저장 실패 시 Core Data 변경사항을 롤백
            do {
                try ImageFileHandler.save(
                    data: originalData,
                    to: memoDirectoryURL,
                    with: originalImageID,
                    fileExtension: fileExtension
                )
                try ImageFileHandler.save(
                    data: thumbnailData,
                    to: memoDirectoryURL,
                    with: thumbnailID,
                    fileExtension: "jpeg"
                )
                try context.save()
            } catch {
                // 파일 저장 중 에러가 발생하면 생성했던 CoreData 객체를 삭제
                self.context.delete(newImageEntity)
                throw error
            }
            
            return newImageEntity.toDomain()
        }
        imageUpdatedSubject.send(.create(memoID: memo.memoID))
        return createdMemoInfo
    }
    
    // MemoImageInfo의 정보를 바탕으로 원본 이미지의 UIImage를 가져오는 함수 (화면에 표시하기 위함)
    func getImage(from imageInfo: MemoImageInfo) async throws -> UIImage {
        let fileURL = try ImageFileHandler.getFileURL(for: imageInfo, thumbnail: false)
        return try ImageFileHandler.loadUIImage(from: fileURL)
    }
    
    // MemoImageInfo의 정보를 바탕으로 썸네일 이미지의 UIImage를 가져오는 함수 (화면에 표시하기 위함)
    func getThumbnailImage(from imageInfo: MemoImageInfo) async throws -> UIImage {
        let fileURL = try ImageFileHandler.getFileURL(for: imageInfo, thumbnail: true)
        return try ImageFileHandler.loadUIImage(from: fileURL)
    }
    
    // 특정 메모가 가진 모든 MemoImageInfo 배열을 반환 (순서 무관. 후에 orderIndex로 정렬하면 됨. 이 함수에서 정렬 후 반환해도 상관없음.)
    func getAllImageInfo(for memo: Memo) async throws -> [MemoImageInfo] {
        try await context.perform {
            let request = ImageEntity.fetchRequest()
            request.predicate = NSPredicate(format: "memo.memoID == %@", memo.memoID as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "orderIndex", ascending: true)]
            
            let entities = try self.context.fetch(request)
            return entities.map { $0.toDomain() }
        }
    }
    
    func updateImageIndex(_ image: MemoImageInfo, newIndex: Int) async throws {
        try await context.perform {
            let request = ImageEntity.fetchRequest()
            request.predicate = NSPredicate(format: "uuid = %@", image.id as CVarArg)
            let fetchResults = try self.context.fetch(request)
            let imageEntity: ImageEntity
            switch fetchResults.count {
            case 0:
                throw CoreDataError.objectNotFound
            case 1:
                imageEntity = fetchResults.first!
            default:
                throw CoreDataError.duplicateImageDetected
            }
            imageEntity.orderIndex = Int64(newIndex)
            imageEntity.temporaryOrderIndex = Int64(newIndex)
            try self.context.save()
        }
        imageUpdatedSubject.send(.update(memoID: image.memoID))
    }
    
    // 이미지를 영구적으로 삭제.
    // 모든 이미지 데이터를 안전하게 삭제하기 위해서 FileManager 에 있는 이미지 및 썸네일 파일을 먼저 지우고,
    // 그 다음에 CoreData의 DB에서 ImageEntity 삭제
    func deleteImage(_ imageInfo: MemoImageInfo) async throws {
        // 파일 시스템에서 파일을 먼저 삭제. 실패해도 DB 삭제는 시도
        let originalURL = try ImageFileHandler.getFileURL(for: imageInfo, thumbnail: false)
        let thumbnailURL = try ImageFileHandler.getFileURL(for: imageInfo, thumbnail: true)
        
        try? ImageFileHandler.delete(at: originalURL)
        try? ImageFileHandler.delete(at: thumbnailURL)
        
        try await context.perform {
            let request = ImageEntity.fetchRequest()
            request.predicate = NSPredicate(format: "uuid == %@", imageInfo.id as CVarArg)
            request.fetchLimit = 1
            
            if let entityToDelete = try self.context.fetch(request).first {
                self.context.delete(entityToDelete)
                try self.context.save()
            }
        }
        imageUpdatedSubject.send(.delete(memoID: imageInfo.memoID))
    }
    
}
