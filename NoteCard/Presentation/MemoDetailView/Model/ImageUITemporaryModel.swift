//
//  ImageUITemporaryModel.swift
//  NoteCard
//
//  Created by 김민성 on 9/13/25.
//

import UIKit

struct ImageUITemporaryModel: TemporaryImageInfo {
    
    let originalImageID: UUID
    let thumbnailID: UUID
    
    let originalImage: UIImage
    let thumbnail: UIImage
    
    var temporaryOrderIndex: Int
    var isTemporaryDeleted: Bool
    var isTemporaryAppended: Bool
    
    let itemProvider: NSItemProvider
    
    /// PHPickerView에서 이미지를 처음 받아오는 경우
    init(temporaryOrderIndex: Int, itemProvider: NSItemProvider) async throws {
        self.originalImageID = UUID()
        self.thumbnailID = UUID()
        self.temporaryOrderIndex = temporaryOrderIndex
        self.isTemporaryDeleted = false
        self.isTemporaryAppended = true
        self.itemProvider = itemProvider
        
        self.originalImage = try await self.itemProvider.loadImageOnly()
        self.thumbnail = try ImageFileHandler.createThumbnailImage(from: originalImage)
    }
    
}
