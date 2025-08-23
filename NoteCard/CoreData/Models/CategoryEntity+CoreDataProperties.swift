//
//  CategoryEntity+CoreDataProperties.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//
//

import Foundation
import CoreData


extension CategoryEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategoryEntity> {
        return NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
    }

    @NSManaged public var creationDate: Date
    @NSManaged public var modificationDate: Date
    @NSManaged public var name: String
    @NSManaged public var memoSet: NSSet

}

// MARK: Generated accessors for memoSet
extension CategoryEntity {

    @objc(addMemoSetObject:)
    @NSManaged public func addToMemoSet(_ value: MemoEntity)

    @objc(removeMemoSetObject:)
    @NSManaged public func removeFromMemoSet(_ value: MemoEntity)

    @objc(addMemoSet:)
    @NSManaged public func addToMemoSet(_ values: NSSet)

    @objc(removeMemoSet:)
    @NSManaged public func removeFromMemoSet(_ values: NSSet)

}

extension CategoryEntity : Identifiable {

}
