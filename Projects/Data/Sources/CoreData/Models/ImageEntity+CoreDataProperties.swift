//
//  ImageEntity+CoreDataProperties.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//
//

import Foundation
import Domain
import Shared
import CoreData


public extension ImageEntity {

    @nonobjc class func fetchRequest() -> NSFetchRequest<ImageEntity> {
        return NSFetchRequest<ImageEntity>(entityName: "ImageEntity")
    }

    @NSManaged var temporaryOrderIndex: Int64
    @NSManaged var orderIndex: Int64
    @NSManaged var uuid: UUID
    @NSManaged var thumbnailUUID: UUID
    @NSManaged var memo: MemoEntity
    @NSManaged var isTemporaryDeleted: Bool
    @NSManaged var isTemporaryAppended: Bool
    @NSManaged var fileExtension: String

}

extension ImageEntity: Identifiable {}
