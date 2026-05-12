//
//  MemoImageInfo.swift
//  NoteCard
//
//  Created by 김민성 on 8/27/25.
//

import Foundation
import DesignSystem
import Shared

public struct MemoImageInfo: Hashable {
    public let id: UUID
    public let thumbnailID: UUID
    public var temporaryOrderIndex: Int
    public var orderIndex: Int
    public let memoID: UUID
    public var isTemporaryDeleted: Bool
    public var isTemporaryAppended: Bool
    public let fileExtension: String

    public init(
        id: UUID,
        thumbnailID: UUID,
        temporaryOrderIndex: Int,
        orderIndex: Int,
        memoID: UUID,
        isTemporaryDeleted: Bool,
        isTemporaryAppended: Bool,
        fileExtension: String
    ) {
        self.id = id
        self.thumbnailID = thumbnailID
        self.temporaryOrderIndex = temporaryOrderIndex
        self.orderIndex = orderIndex
        self.memoID = memoID
        self.isTemporaryDeleted = isTemporaryDeleted
        self.isTemporaryAppended = isTemporaryAppended
        self.fileExtension = fileExtension
    }
}
