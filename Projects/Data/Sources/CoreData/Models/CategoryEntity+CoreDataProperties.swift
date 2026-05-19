//
//  CategoryEntity+CoreDataProperties.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//
//

import Foundation
import Domain
import Shared
import CoreData


public extension CategoryEntity {

    @nonobjc class func fetchRequest() -> NSFetchRequest<CategoryEntity> {
        return NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
    }

    @NSManaged var creationDate: Date
    @NSManaged var modificationDate: Date
    @NSManaged var name: String
    @NSManaged var memoSet: NSSet

}

// MARK: Generated accessors for memoSet
public extension CategoryEntity {

    @objc(addMemoSetObject:)
    @NSManaged func addToMemoSet(_ value: MemoEntity)

    @objc(removeMemoSetObject:)
    @NSManaged func removeFromMemoSet(_ value: MemoEntity)

    @objc(addMemoSet:)
    @NSManaged func addToMemoSet(_ values: NSSet)

    @objc(removeMemoSet:)
    @NSManaged func removeFromMemoSet(_ values: NSSet)

}

extension CategoryEntity: Identifiable {}
