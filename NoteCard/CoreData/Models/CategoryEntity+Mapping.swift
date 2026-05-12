//
//  CategoryEntity+Mapping.swift
//  NoteCard
//
//  Created by 김민성 on 8/27/25.
//

import CoreData
import Domain
import DesignSystem
import Shared

extension CategoryEntity {
    
    func toDomain() -> Domain.Category {
        Domain.Category(
            name: self.name,
            creationDate: self.creationDate,
            modificationDate: self.modificationDate,
        )
    }
    
}

extension Domain.Category {
    
    func toEntity(in context: NSManagedObjectContext) -> CategoryEntity {
        let request = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name as CVarArg)

        if let existingCategoryEntity = try? context.fetch(request).first {
            return existingCategoryEntity
        } else {
            let newEntity = CategoryEntity(context: context)
            newEntity.name = self.name
            return newEntity
        }
    }
    
}
