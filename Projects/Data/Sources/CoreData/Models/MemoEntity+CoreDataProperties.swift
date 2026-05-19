//
//  MemoEntity+CoreDataProperties.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//
//

import Foundation
import Domain
import Shared
import CoreData


public extension MemoEntity {

    @nonobjc class func fetchRequest() -> NSFetchRequest<MemoEntity> {
        return NSFetchRequest<MemoEntity>(entityName: "MemoEntity")
    }

    @NSManaged var creationDate: Date
    @NSManaged var deletedDate: Date?
    @NSManaged var isFavorite: Bool
    @NSManaged var isInTrash: Bool
    @NSManaged var memoID: UUID
    @NSManaged var memoText: String
    @NSManaged var memoTitle: String
    @NSManaged var modificationDate: Date
    @NSManaged var categories: NSSet
    @NSManaged var images: NSSet

}

// MARK: Generated accessors for categories
public extension MemoEntity {

    @objc(addCategoriesObject:)
    @NSManaged func addToCategories(_ value: CategoryEntity)

    @objc(removeCategoriesObject:)
    @NSManaged func removeFromCategories(_ value: CategoryEntity)

    @objc(addCategories:)
    @NSManaged func addToCategories(_ values: NSSet)

    @objc(removeCategories:)
    @NSManaged func removeFromCategories(_ values: NSSet)

}

// MARK: Generated accessors for images
public extension MemoEntity {

    @objc(addImagesObject:)
    @NSManaged func addToImages(_ value: ImageEntity)

    @objc(removeImagesObject:)
    @NSManaged func removeFromImages(_ value: ImageEntity)

    @objc(addImages:)
    @NSManaged func addToImages(_ values: NSSet)

    @objc(removeImages:)
    @NSManaged func removeFromImages(_ values: NSSet)

}

extension MemoEntity: Identifiable {}
