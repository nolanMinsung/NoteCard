//
//  CategoryEntity+CoreDataClass.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//
//

import Foundation
import CoreData

@objc(CategoryEntity)
public class CategoryEntity: NSManagedObject {
    
    @available(*, unavailable)
    public init() {
        fatalError()
    }
    
    @objc
    override private init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(context: NSManagedObjectContext) {
        guard let entityDescription = NSEntityDescription.entity(
            forEntityName: "CategoryEntity",
            in: context
        ) else { fatalError() }
        super.init(entity: entityDescription, insertInto: context)
        
        creationDate = .now
        modificationDate = .now
    }
    
}
