//
//  MemoPreviewDTO.swift
//  NoteCard
//
//  Created by 김민성 on 8/23/25.
//

import Foundation

struct MemoPreviewDTO: Hashable {
    
    let memoID: UUID
    let memoTitlePreview: String
    let memoTextPreview: String
    let creationDate: Date
    let modificationDate: Date
    let deletedDate: Date?
    let isFavorite: Bool
    let isInTrash: Bool
    let imageCount: Int
    
    init(from memoEntity: MemoEntity) {
        self.memoID = memoEntity.memoID
        self.memoTitlePreview = String(memoEntity.memoTitle.prefix(150))
        self.memoTextPreview = String(memoEntity.memoText.prefix(250))
        self.creationDate = memoEntity.creationDate
        self.modificationDate = memoEntity.modificationDate
        self.deletedDate = memoEntity.deletedDate
        self.isFavorite = memoEntity.isFavorite
        self.isInTrash = memoEntity.isInTrash
        self.imageCount = memoEntity.images.count
    }
    
}
