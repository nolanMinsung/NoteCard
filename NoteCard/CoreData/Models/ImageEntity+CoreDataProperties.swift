//
//  ImageEntity+CoreDataProperties.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//
//

import Foundation
import CoreData


extension ImageEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ImageEntity> {
        return NSFetchRequest<ImageEntity>(entityName: "ImageEntity")
    }

    @NSManaged public var temporaryOrderIndex: Int64
    @NSManaged public var orderIndex: Int64
    @NSManaged public var uuid: UUID
    @NSManaged public var thumbnailUUID: UUID
    @NSManaged public var memo: MemoEntity
    @NSManaged public var isTemporaryDeleted: Bool
    @NSManaged public var isTemporaryAppended: Bool
    @NSManaged public var fileExtension: String

}

extension ImageEntity : Identifiable {

}
