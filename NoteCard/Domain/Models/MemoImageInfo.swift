//
//  MemoImageInfo.swift
//  NoteCard
//
//  Created by 김민성 on 8/27/25.
//

import Foundation

struct MemoImageInfo {
    let id: UUID
    let thumbnailID: UUID
    var temporaryOrderIndex: Int
    var orderIndex: Int
    let memo: MemoEntity
    var isTemporaryDeleted: Bool
    var isTemporaryAppended: Bool
}
