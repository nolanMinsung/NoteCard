//
//  ImageUIModel.swift
//  NoteCard
//
//  Created by 김민성 on 9/12/25.
//

import UIKit

struct ImageUIModel: Hashable, TemporaryImageInfo {
    
    var info: MemoImageInfo
    
    var originalImageID: UUID { info.id }
    var thumbnailID: UUID { info.thumbnailID }
    
    let originalImage: UIImage
    let thumbnail: UIImage
    
    var temporaryOrderIndex: Int {
        get { info.temporaryOrderIndex }
        set { info.temporaryOrderIndex = newValue }
    }
    var isTemporaryDeleted: Bool {
        get { info.isTemporaryDeleted }
        set { info.isTemporaryDeleted = newValue }
    }
    var isTemporaryAppended: Bool {
        get { info.isTemporaryAppended }
        set { info.isTemporaryAppended = newValue }
    }
    
    init(from imageInfo: MemoImageInfo, image: UIImage, thumbnail: UIImage) {
        self.info = imageInfo
        self.originalImage = image
        self.thumbnail = thumbnail
    }
    
}
