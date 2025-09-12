//
//  ImageUIModel.swift
//  NoteCard
//
//  Created by 김민성 on 9/12/25.
//

import UIKit

struct ImageUIModel: Hashable {
    let id: UUID
    let thumbnailID: UUID
    var temporaryOrderIndex: Int
    var orderIndex: Int
    let memoID: UUID
    var isTemporaryDeleted: Bool
    var isTemporaryAppended: Bool
    let fileExtension: String
    
    let originalImage: UIImage
    let thumbnail: UIImage
    
    init(from imageInfo: MemoImageInfo, image: UIImage, thumbnail: UIImage) {
        self.id = imageInfo.id
        self.thumbnailID = imageInfo.thumbnailID
        self.temporaryOrderIndex = imageInfo.temporaryOrderIndex
        self.orderIndex = imageInfo.orderIndex
        self.memoID = imageInfo.memoID
        self.isTemporaryDeleted = imageInfo.isTemporaryDeleted
        self.isTemporaryAppended = imageInfo.isTemporaryAppended
        self.fileExtension = imageInfo.fileExtension
        self.originalImage = image
        self.thumbnail = thumbnail
    }
    
}
