//
//  CategoryEntityRepository.swift
//  NoteCard
//
//  Created by 김민성 on 8/28/25.
//

import Foundation

protocol ComparableValue: Comparable {}
extension String: ComparableValue {}
extension Date: ComparableValue {}

actor CategoryEntityRepository: CategoryRepository {
    
    static let shared = CategoryEntityRepository()
    private init() { }
    
    private let context = CoreDataStack.shared.backgroundContext
    
    private func categoryNameEqual(to name: String) -> NSPredicate {
        return NSPredicate(format: "name == %@", name as CVarArg)
    }
    private func categoryHasMemo(memo: Memo) -> NSPredicate {
        return NSPredicate(format: "ANY memoSet.memoID == %@", memo.memoID as CVarArg)
    }
    private func categoryNameContains(searchText: String) -> NSPredicate {
        return NSPredicate(format: "name CONTAINS[c] %@", searchText)
    }
}


extension CategoryEntityRepository {
    
    private func fetchMemoEntity(id: UUID) throws -> MemoEntity {
        let request = MemoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "memoID == %@ && isInTrash == false", id as CVarArg)
        let foundMemo = try self.context.fetch(request)
        switch foundMemo.count {
        case 0:
            throw MemoEntityError.memoNotFound(id: id)
        case 1:
            return foundMemo.first!
        default:
            throw MemoEntityError.duplicateMemoDetected
        }
    }
    
}


extension CategoryEntityRepository {
    
    private func fetchCategoryEntity(name: String) throws -> CategoryEntity {
        let request = CategoryEntity.fetchRequest()
        request.predicate = categoryNameEqual(to: name)
        let foundCategory = try self.context.fetch(request)
        switch foundCategory.count {
        case 0:
            throw CoreDataError.categoryNotFound(name: name)
        case 1:
            return foundCategory.first!
        default:
            throw CoreDataError.duplicateCategoryDetected
        }
    }
    
    func create(name: String) async throws {
        let allCategoryNames = try await getAllCategories(inOrderOf: .modificationDate, isAscending: false).map(\.name)
        guard !allCategoryNames.contains(name) else {
            throw CoreDataError.duplicateCategoryDetected
        }
        try await context.perform { [unowned self] in
            let newCategory = CategoryEntity(context: self.context)
            newCategory.name = name
            try self.context.save()
        }
    }
    
    func getAllCategories(inOrderOf orderCriterion: CategoryProperties, isAscending: Bool) async throws -> [Category] {
        try await context.perform { [unowned self] in
            let request = CategoryEntity.fetchRequest()
            let modificationDate = NSSortDescriptor(key: "modificationDate", ascending: isAscending)
            let creationDate = NSSortDescriptor(key: "creationDate", ascending: isAscending)
            request.sortDescriptors = [modificationDate, creationDate]
            return try self.context.fetch(request).map { $0.toDomain() }
        }
    }
    
    func getAllCategories(
        ofMemo memo: Memo,
        inOrderOf orderCriterion: CategoryProperties,
        isAscending: Bool
    ) async throws -> [Category] {
        try await context.perform { [unowned self] in
            let request = CategoryEntity.fetchRequest()
            let modificationDate = NSSortDescriptor(key: "modificationDate", ascending: isAscending)
            let creationDate = NSSortDescriptor(key: "creationDate", ascending: isAscending)
            request.sortDescriptors = [modificationDate, creationDate]
            request.predicate = categoryHasMemo(memo: memo)
            return try self.context.fetch(request).map { $0.toDomain() }
        }
    }
    
    func searchCategory(_ searchText: String, inOrderOf orderCriterion: CategoryProperties, isAscending: Bool) async throws -> [Category] {
        try await context.perform { [unowned self] in
            let request = CategoryEntity.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: orderCriterion.rawValue, ascending: isAscending)
            request.sortDescriptors = [sortDescriptor]
            request.predicate = categoryNameContains(searchText: searchText)
            return try self.context.fetch(request).map { $0.toDomain() }
        }
    }
    
    func changeCategoryName(_ category: Category, newName: String) async throws {
        let allCategoryNames = try await getAllCategories(inOrderOf: .modificationDate, isAscending: false).map(\.name)
        guard !allCategoryNames.contains(newName) else {
            throw CoreDataError.duplicateCategoryDetected
        }
        try await context.perform { [unowned self] in
            let categoryEntity = try fetchCategoryEntity(name: category.name)
            categoryEntity.name = newName
            try context.save()
        }
    }
    
    func deleteCategory(_ category: Category) async throws {
        try await context.perform { [unowned self] in
            let categoryEntity = try fetchCategoryEntity(name: category.name)
            context.delete(categoryEntity)
            try context.save()
        }
    }
    
    func memoCount(of category: Category) async throws -> Int {
        try await context.perform { [unowned self] in
            let categoryEntity = try fetchCategoryEntity(name: category.name)
            return categoryEntity.memoSet.count
        }
    }
    
    func updateModificationDate(of category: Category) async throws {
        try await context.perform { [unowned self] in
            let categoryEntity = try fetchCategoryEntity(name: category.name)
            categoryEntity.modificationDate = .now
        }
    }
    
}
