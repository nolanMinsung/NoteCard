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
    
    @available(*, unavailable)
    public init(context: NSManagedObjectContext) {
        fatalError()
    }
    
    @objc
    override private init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(
        temporaryOrderIndex: Int,
        orderIndex: Int,
        uuid: UUID,
        thumbnailUUID: UUID,
        memo: MemoEntity,
        isTemporaryAppended: Bool,
        context: NSManagedObjectContext
    ) {
        guard let entityDescription = NSEntityDescription.entity(
            forEntityName: "ImageEntity",
            in: context
        ) else {
            fatalError()
        }
        super.init(entity: entityDescription, insertInto: context)
        
        isTemporaryDeleted = false
    }
    
}
