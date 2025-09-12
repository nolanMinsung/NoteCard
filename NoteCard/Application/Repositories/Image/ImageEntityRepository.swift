//
//  ImageEntityRepository.swift
//  NoteCard
//
//  Created by 김민성 on 9/10/25.
//

import CoreData
import PhotosUI
import UIKit
import UniformTypeIdentifiers

actor ImageEntityRepository: ImageRepository {
    
    static let shared = ImageEntityRepository()
    private init() { }
    
    private let context = CoreDataStack.shared.backgroundContext
    
    func createImage(
        from pickerResult: PHPickerResult,
        for memo: Memo,
        orderIndex: Int,
        isTemporary: Bool
    ) async throws -> MemoImageInfo {
        
        let (originalData, originalType) = try await ImageFileHandler.prepareImageData(from: pickerResult.itemProvider)
        let thumbnailData = try ImageFileHandler.createThumbnailData(from: originalData)
        
        // MemoEntity 불러오기(후에 ImageEntity에서 생성자의 매개변수로 넣기 위함)
        let memoEntity = try await MemoEntityRepository.shared.fetchMemoEntity(id: memo.memoID)
        
        return try await context.perform { [unowned self] in
            // 코어데이터에 저장할 데이터
            let orderIndex: Int64 = Int64(min(max(0, orderIndex), Int(Int64.max)))
            let originalImageID = UUID()
            let thumbnailID = UUID()
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
    }
    
}


enum NSItemProviderError: LocalizedError {
    case loadedButDataNotFound
    
    var errorDescription: String? {
        switch self {
        case .loadedButDataNotFound:
            return "데이터 로딩에는 성공했으나, 받아온 data가 없음(nil)."
        }
    }
}


private extension NSItemProvider {
    
    func loadDataRepresentation(for contentType: UTType) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            if #available(iOS 16, *) {
                let _ = loadDataRepresentation(for: contentType) { data, error in
                    switch (data, error) {
                    case (_, .some(let error)):
                        // 에러 발생
                        continuation.resume(throwing: error)
                    case (.some(let data), .none):
                        continuation.resume(returning: data)
                    case (.none, .none):
                        // 에러는 없는데 데이터도 없는 이상한 상황
                        continuation.resume(throwing: NSItemProviderError.loadedButDataNotFound)
                    }
                }
                
            } else {
                let _ = loadDataRepresentation(forTypeIdentifier: contentType.identifier) { data, error in
                    switch (data, error) {
                    case (_, .some(let error)):
                        // 에러 발생
                        continuation.resume(throwing: error)
                    case (.some(let data), .none):
                        continuation.resume(returning: data)
                    case (.none, .none):
                        // 에러는 없는데 데이터도 없는 이상한 상황
                        continuation.resume(throwing: NSItemProviderError.loadedButDataNotFound)
                    }
                }
                
            }
        }
    }
    
}
