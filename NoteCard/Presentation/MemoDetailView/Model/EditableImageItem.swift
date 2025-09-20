//
//  EditableImageItem.swift
//  NoteCard
//
//  Created by 김민성 on 9/18/25.
//

import UIKit

enum EditableImageItem: Hashable {
    case existing(model: ImageUIModel)
    case pendingAddition(model: ImageUITemporaryModel)
    case pendingDeletion(model: ImageUIModel)
    
    var model: any TemporaryImageInfo {
        switch self {
        case .existing(let model):            model
        case .pendingAddition(let model):     model
        case .pendingDeletion(let model):     model
        }
    }
    
}
