//
//  TemporaryImageInfo.swift
//  NoteCard
//
//  Created by 김민성 on 9/13/25.
//

import UIKit

protocol TemporaryImageInfo {
    
    var originalImageID: UUID { get }
    var thumbnailID: UUID { get }
    
    var originalImage: UIImage { get }
    var thumbnail: UIImage { get }
    
    var temporaryOrderIndex: Int { get set }
    var isTemporaryDeleted: Bool { get set }
    var isTemporaryAppended: Bool { get set }
    
}
