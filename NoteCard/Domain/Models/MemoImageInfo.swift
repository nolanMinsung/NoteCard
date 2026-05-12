//
//  MemoImageInfo.swift
//  NoteCard
//
//  Created by 김민성 on 8/27/25.
//

import Foundation
import Shared

struct MemoImageInfo: Hashable {
    let id: UUID
    let thumbnailID: UUID
    var temporaryOrderIndex: Int
    var orderIndex: Int
    let memoID: UUID
    var isTemporaryDeleted: Bool
    var isTemporaryAppended: Bool
    let fileExtension: String
}
