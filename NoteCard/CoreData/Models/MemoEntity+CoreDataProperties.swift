//
//  MemoEntity+CoreDataProperties.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//
//

import Foundation
import CoreData


extension MemoEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MemoEntity> {
        return NSFetchRequest<MemoEntity>(entityName: "MemoEntity")
    }

    @NSManaged public var creationDate: Date
    @NSManaged public var deletedDate: Date?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var isInTrash: Bool
    @NSManaged public var memoID: UUID
    @NSManaged public var memoText: String
    @NSManaged public var memoTitle: String
    @NSManaged public var modificationDate: Date
    @NSManaged public var categories: NSSet
    @NSManaged public var images: NSSet

}

// MARK: Generated accessors for categories
extension MemoEntity {

    @objc(addCategoriesObject:)
    @NSManaged public func addToCategories(_ value: CategoryEntity)

    @objc(removeCategoriesObject:)
    @NSManaged public func removeFromCategories(_ value: CategoryEntity)

    @objc(addCategories:)
    @NSManaged public func addToCategories(_ values: NSSet)

    @objc(removeCategories:)
    @NSManaged public func removeFromCategories(_ values: NSSet)

}

// MARK: Generated accessors for images
extension MemoEntity {

    @objc(addImagesObject:)
    @NSManaged public func addToImages(_ value: ImageEntity)

    @objc(removeImagesObject:)
    @NSManaged public func removeFromImages(_ value: ImageEntity)

    @objc(addImages:)
    @NSManaged public func addToImages(_ values: NSSet)

    @objc(removeImages:)
    @NSManaged public func removeFromImages(_ values: NSSet)

}

extension MemoEntity : Identifiable {

}
