//
//  ImageFileHandler.swift
//  NoteCard
//
//  Created by 김민성 on 9/10/25.
//

import UIKit
import PhotosUI
import UniformTypeIdentifiers

// MARK: - ImageFileHandler
/// 이미지 데이터와 파일 시스템을 다루는 유틸리티 네임스페이스
enum ImageFileHandler {

    // MARK: - Data Preparation
    
    /// `PHPickerResult`의 `provider`에서 원본 이미지 데이터를 비동기적으로 로드.
    static func prepareImageData(from provider: NSItemProvider) async throws(ImageFileError) -> (data: Data, type: UTType) {
        if let heicData = try? await provider.loadDataRepresentation(for: .heic) {
            return (heicData, .heic)
        } else if let jpegData = try? await provider.loadDataRepresentation(for: .jpeg) {
            return (jpegData, .jpeg)
        } else {
            throw ImageFileError.loadingDataFromNSProviderFaild
        }
    }
    
    /// 원본 이미지 데이터로부터 썸네일 데이터를 생성.
    static func createThumbnailData(from originalData: Data, maxPixelSize: CGFloat = 400) throws -> Data {
        guard let sourceImage = UIImage(data: originalData) else {
            throw ImageFileError.dataToImageConversionFailed
        }
        return try createThumbnailData(from: sourceImage, maxPixelSize: maxPixelSize)
    }
    
    static func createThumbnailData(from sourceImage: UIImage, maxPixelSize: CGFloat = 400) throws -> Data {
        let resizedImage = try createThumbnailImage(from: sourceImage, maxPixelSize: maxPixelSize)
        guard let thumbnailData = resizedImage.jpegData(compressionQuality: 0.7) else {
            throw ImageFileError.thumbnailCreationError
        }
        return thumbnailData
    }
    
    static func createThumbnailImage(from sourceImage: UIImage, maxPixelSize: CGFloat = 400) throws -> UIImage {
        let size = sourceImage.size
        let newSize: CGSize
        
        if size.width <= maxPixelSize && size.height <= maxPixelSize {
            newSize = size
        } else {
            let scale = (size.width > size.height) ? (maxPixelSize / size.width) : (maxPixelSize / size.height)
            newSize = CGSize(width: size.width * scale, height: size.height * scale)
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            sourceImage.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }

    // MARK: - File System Operations
    
    /// 주어진 데이터를 특정 경로에 파일로 저장.
    static func save(data: Data, to directory: URL, with id: UUID, fileExtension: String) throws {
        let fileURL = directory
            .appendingPathComponent(id.uuidString)
            .appendingPathExtension(fileExtension)
        do {
            try data.write(to: fileURL)
        } catch {
            throw ImageFileError.saveError(error)
        }
    }

    /// 특정 경로의 파일을 로드하여 UIImage로 반환.
    static func loadUIImage(from fileURL: URL) throws -> UIImage {
        do {
            let data = try Data(contentsOf: fileURL)
            guard let image = UIImage(data: data) else {
                throw ImageFileError.dataToImageConversionFailed
            }
            return image
        } catch {
            throw ImageFileError.imageLoadingError(error)
        }
    }
    
    /// 특정 경로의 파일을 삭제.
    static func delete(at fileURL: URL) throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                throw ImageFileError.fileDeleteError(error)
            }
        }
    }

    // MARK: - Path Management
    
    /// 특정 메모 ID에 대한 디렉토리 URL을 가져오고, 없으면 생성.
    static func getDirectory(for memoID: UUID) throws -> URL {
        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw ImageFileError.fileURLGenerationFailed
        }
        let memoDirectory = documentDirectory.appendingPathComponent(memoID.uuidString)
        
        if !fileManager.fileExists(atPath: memoDirectory.path) {
            try fileManager.createDirectory(at: memoDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return memoDirectory
    }

    /// 이미지 정보를 바탕으로 파일 전체 URL을 불러옴.
    static func getFileURL(for imageInfo: MemoImageInfo, thumbnail: Bool = false) throws -> URL {
        let directory = try getDirectory(for: imageInfo.memoID)
        let imageID = thumbnail ? imageInfo.thumbnailID : imageInfo.id
        
        let primaryExtension = thumbnail ? "jpeg" : imageInfo.fileExtension
        
        let primaryURL = directory
            .appendingPathComponent(imageID.uuidString)
            .appendingPathExtension(primaryExtension)
        
        if FileManager.default.fileExists(atPath: primaryURL.path) {
            return primaryURL
        }
        
        // 파일이 없고, 기본 확장자가 "jpeg"였다면, 레거시 확장자인 "jpg"로 다시 시도.
        // (썸네일의 경우도 .jpeg가 없으면 .jpg로 검색)
        if primaryExtension == "jpeg" {
            let legacyURL = directory
                .appendingPathComponent(imageID.uuidString)
                .appendingPathExtension("jpg")
            
            if FileManager.default.fileExists(atPath: legacyURL.path) {
                return legacyURL
            }
        }
        
        throw ImageFileError.fileNotFound
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
                        continuation.resume(throwing: ImageFileError.loadedFromNSProviderButDataNotFound)
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
                        continuation.resume(throwing: ImageFileError.loadedFromNSProviderButDataNotFound)
                    }
                }
            }
        }
    }
    
}


extension NSItemProvider {
    
    func loadImageOnly() async throws -> UIImage {
        guard self.canLoadObject(ofClass: UIImage.self) else {
            throw ImageFileError.loadingDataFromNSProviderFaild
        }
        return try await withCheckedThrowingContinuation { continuation in
            loadObject(ofClass: UIImage.self) { providerReading, error in
                switch (providerReading, error) {
                case (_, .some(let error)):
                    // 에러 발생
                    continuation.resume(throwing: error)
                case (.some(let data), .none):
                    guard let image = data as? UIImage else {
                        continuation.resume(throwing: ImageFileError.loadingDataFromNSProviderFaild)
                        return
                    }
                    continuation.resume(returning: image)
                case (.none, .none):
                    // 에러는 없는데 데이터도 없는 이상한 상황
                    continuation.resume(throwing: ImageFileError.loadedFromNSProviderButDataNotFound)
                }
            }
        }
    }
    

}
