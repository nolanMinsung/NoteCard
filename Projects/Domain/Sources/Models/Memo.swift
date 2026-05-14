//
//  Memo.swift
//  NoteCard
//
//  Created by 김민성 on 8/27/25.
//

import Foundation
import Shared

public struct Memo: Hashable {
    public let memoID: UUID
    public let creationDate: Date
    public var modificationDate: Date
    public var deletedDate: Date?
    public var isFavorite: Bool
    public var isInTrash: Bool
    public var memoText: String
    public var memoTitle: String
    public var categories: Set<Category>
    public var images: Set<MemoImageInfo>

    public init(
        memoID: UUID,
        creationDate: Date,
        modificationDate: Date,
        deletedDate: Date?,
        isFavorite: Bool,
        isInTrash: Bool,
        memoText: String,
        memoTitle: String,
        categories: Set<Category>,
        images: Set<MemoImageInfo>
    ) {
        self.memoID = memoID
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.deletedDate = deletedDate
        self.isFavorite = isFavorite
        self.isInTrash = isInTrash
        self.memoText = memoText
        self.memoTitle = memoTitle
        self.categories = categories
        self.images = images
    }
}
