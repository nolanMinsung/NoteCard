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

    /// v3에서 추가된 안정 식별자. v2 store에는 없으므로 optional로 유지하고 앱 시작 시 `CategoryUUIDBackfiller`로 채움.
    @NSManaged var categoryID: UUID?
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
