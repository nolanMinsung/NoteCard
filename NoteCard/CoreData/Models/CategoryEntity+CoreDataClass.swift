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
    
    static let categoryManager = CategoryEntityManager.shared
    static var numberOfCategories: Int {
        let array = categoryManager.getCategoryEntities(inOrderOf: CategoryProperties.creationDate, isAscending: false)
        return array.count
    }
}
