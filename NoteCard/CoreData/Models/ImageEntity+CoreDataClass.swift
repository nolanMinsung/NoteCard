//
//  ImageEntity+CoreDataClass.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//
//

import Foundation
import CoreData

@objc(ImageEntity)
public class ImageEntity: NSManagedObject {
    
    @available(*, unavailable)
    public init() {
        fatalError()
    }
    
    @objc
    override private init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(
        uuid: UUID,
        thumbnailUUID: UUID,
        temporaryOrderIndex: Int64,
        orderIndex: Int64,
        isTemporaryAppended: Bool,
        fileExtension: String,
        memo: MemoEntity,
        context: NSManagedObjectContext
    ) {
        guard let entityDescription = NSEntityDescription.entity(
            forEntityName: "ImageEntity",
            in: context
        ) else {
            fatalError()
        }
        super.init(entity: entityDescription, insertInto: context)
        self.uuid = uuid
        self.thumbnailUUID = thumbnailUUID
        self.temporaryOrderIndex = temporaryOrderIndex
        self.orderIndex = orderIndex
        self.isTemporaryDeleted = false
        self.isTemporaryAppended = isTemporaryAppended
        self.fileExtension = fileExtension
        self.memo = memo   
    }
    
}
