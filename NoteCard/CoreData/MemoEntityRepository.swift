//
//  MemoEntityRepository.swift
//  NoteCard
//
//  Created by 김민성 on 8/20/25.
//

import CoreData
import Foundation

actor MemoEntityRepository {
    
    static let shared = MemoEntityRepository()
    private init() { }
    
    private let context = CoreDataStack.shared.backgroundContext
    
    @UserDefault<String>(key: .orderCriterion, defaultValue: OrderCriterion.modificationDate.rawValue)
    private var orderCriterion: String
    
    @UserDefault<Bool>(key: .isOrderAscending, defaultValue: false)
    private var isOrderAscending: Bool
    
}


// MARK: - CREATE
extension MemoEntityRepository {
    
    func createNewMemo() async throws -> MemoEntity {
        try await context.perform {
            let newMemoEntity = MemoEntity(context: self.context)
            try self.context.save()
            return newMemoEntity
        }
    }
    
}


// MARK: - READ
extension MemoEntityRepository {
    
    func getAllMemo() async throws -> [MemoEntity]  {
        try await context.perform {
            let request = MemoEntity.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: self.orderCriterion, ascending: self.isOrderAscending)
            request.sortDescriptors = [sortDescriptor]
            return try self.context.fetch(request)
        }
    }
    
    func getFilteredMemo(inCategory category: CategoryEntity) async throws -> [MemoEntity] {
        try await context.perform {
            let request = MemoEntity.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: self.orderCriterion, ascending: self.isOrderAscending)
            request.sortDescriptors = [sortDescriptor]
            request.predicate = NSPredicate(
                format: "ANY categories == %@ && isInTrash == false",
                category as CVarArg
            )
            return try self.context.fetch(request)
        }
    }
    
    func getMemoInTrash() async throws -> [MemoEntity] {
        try await context.perform {
            let request = MemoEntity.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: self.orderCriterion, ascending: self.isOrderAscending)
            request.sortDescriptors = [sortDescriptor]
            request.predicate = NSPredicate(format: "isInTrash == true")
            return try self.context.fetch(request)
        }
    }
    
    func searchMemo(searchText: String, inCategory: CategoryEntity? = nil) async throws -> [MemoEntity] {
        try await context.perform {
            let request = MemoEntity.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: self.orderCriterion, ascending: self.isOrderAscending)
            request.sortDescriptors = [sortDescriptor]
            guard !searchText.isEmpty else {
                return []
            }
            request.predicate = NSPredicate(
                format: "(memoTitle CONTAINS[c] %@ || memoText CONTAINS[c] %@) && isInTrash == false",
                searchText,
                searchText
            )
            return try self.context.fetch(request)
        }
    }
    
    func getFavoriteMemo() async throws -> [MemoEntity] {
        try await context.perform {
            let request = MemoEntity.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: self.orderCriterion, ascending: self.isOrderAscending)
            request.sortDescriptors = [sortDescriptor]
            request.predicate = NSPredicate(format: "isFavorite == true && isInTrash == false")
            return try self.context.fetch(request)
        }
    }
    
}


// MARK: - DELETE(Soft)
extension MemoEntityRepository {
    
    func moveToTrash(_ memoEntity: MemoEntity) async throws {
        try await context.perform {
            memoEntity.isFavorite = false
            memoEntity.isInTrash = true
            memoEntity.deletedDate = .now
            guard let categories = memoEntity.categories as? Set<CategoryEntity> else {
                fatalError("memo's categories casting failed")
            }
            for category in categories {
                memoEntity.removeFromCategories(category)
            }
            try self.context.save()
        }
    }
    
}


// MARK: - RESTORING
extension MemoEntityRepository {
    
    func restore(_ memoEntity: MemoEntity) async throws {
        try await context.perform {
            memoEntity.isInTrash = false
            memoEntity.deletedDate = nil
            try self.context.save()
        }
    }
    
}
