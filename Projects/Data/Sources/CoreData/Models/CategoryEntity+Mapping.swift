//
//  CategoryEntity+Mapping.swift
//  NoteCard
//
//  Created by 김민성 on 8/27/25.
//

import CoreData
import Domain
import Shared

public extension CategoryEntity {

    func toDomain() -> Domain.Category {
        let id: UUID
        if let existing = self.categoryID {
            id = existing
        } else {
            // backfill 누락 방어. assertionFailure로 dev 즉시 trap, release에선 self-heal로 새 UUID 부여.
            assertionFailure("CategoryEntity.categoryID nil — CategoryUUIDBackfiller가 누락된 상태일 수 있음")
            id = UUID()
            self.categoryID = id
        }
        return Domain.Category(
            id: id,
            name: self.name,
            creationDate: self.creationDate,
            modificationDate: self.modificationDate
        )
    }

}

public extension Domain.Category {

    func toEntity(in context: NSManagedObjectContext) -> CategoryEntity {
        let request = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "categoryID == %@", id as CVarArg)

        if let existingCategoryEntity = try? context.fetch(request).first {
            return existingCategoryEntity
        } else {
            let newEntity = CategoryEntity(context: context)
            newEntity.categoryID = self.id
            newEntity.name = self.name
            return newEntity
        }
    }

}
