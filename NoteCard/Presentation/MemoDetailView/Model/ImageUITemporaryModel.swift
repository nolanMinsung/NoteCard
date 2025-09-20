//
//  ImageUITemporaryModel.swift
//  NoteCard
//
//  Created by 김민성 on 9/13/25.
//

import PhotosUI
import UIKit

struct ImageUITemporaryModel: TemporaryImageInfo {
    
    let originalImageID: UUID
    let thumbnailID: UUID
    
    let originalImage: UIImage
    let thumbnail: UIImage
    
    var temporaryOrderIndex: Int
    var isTemporaryDeleted: Bool
    var isTemporaryAppended: Bool
    
    let pickerResult: PHPickerResult
    
    /// PHPickerView에서 이미지를 처음 받아오는 경우
    init(temporaryOrderIndex: Int, pickerResult: PHPickerResult) async throws {
        self.originalImageID = UUID()
        self.thumbnailID = UUID()
        self.temporaryOrderIndex = temporaryOrderIndex
        self.isTemporaryDeleted = false
        self.isTemporaryAppended = true
        self.pickerResult = pickerResult
        
        self.originalImage = try await self.pickerResult.itemProvider.loadImageOnly()
        self.thumbnail = try ImageFileHandler.createThumbnailImage(from: originalImage)
    }
    
}
