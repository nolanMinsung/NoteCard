//
//  Memo.swift
//  NoteCard
//
//  Created by 김민성 on 8/27/25.
//

import Foundation

struct Memo: Hashable {
    let memoID: UUID
    let creationDate: Date
    var modificationDate: Date
    var deletedDate: Date?
    var isFavorite: Bool
    var isInTrash: Bool
    var memoText: String
    var memoTitle: String
    var categories: Set<Category>
    var images: Set<MemoImageInfo>
}
