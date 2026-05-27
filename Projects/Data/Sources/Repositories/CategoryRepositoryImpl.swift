//
//  CategoryRepositoryImpl.swift
//  NoteCard
//
//  Created by 김민성 on 8/28/25.
//

import Combine
import Foundation
import CoreData
import Domain
import Shared

public protocol ComparableValue: Comparable {}
extension String: ComparableValue {}
extension Date: ComparableValue {}

public final class CategoryRepositoryImpl: CategoryRepository, @unchecked Sendable {

    private let stackResolver: () -> CoreDataStack

    private var context: NSManagedObjectContext {
        stackResolver().backgroundContext
    }

    // MARK: - Subjects, Publisher

    private let categoryUpdatedSubject = PassthroughSubject<CategoryUpdateType, Never>()
    public var categoryUpdatedPublisher: AnyPublisher<CategoryUpdateType, Never> {
        categoryUpdatedSubject.eraseToAnyPublisher()
    }

    // MARK: - Init

    public init(dataLayer: UserScopedDataLayer) {
        self.stackResolver = { dataLayer.currentStack }
    }

    /// 단일 stack을 들고 사용자 변경에 반응하지 않는 테스트 편의 init.
    internal init(stack: CoreDataStack) {
        self.stackResolver = { stack }
    }
    
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


public extension CategoryRepositoryImpl {
    
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


public extension CategoryRepositoryImpl {
    
    private func fetchCategoryEntity(id: UUID) throws -> CategoryEntity {
        let request = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "categoryID == %@", id as CVarArg)
        let foundCategory = try self.context.fetch(request)
        switch foundCategory.count {
        case 0:
            throw CoreDataError.categoryNotFound(id: id)
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
            newCategory.categoryID = UUID()
            newCategory.name = name
            try self.context.save()
        }
        categoryUpdatedSubject.send(.create)
    }
    
    func getAllCategories(inOrderOf orderCriterion: CategoryProperties, isAscending: Bool) async throws -> [Domain.Category] {
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
    ) async throws -> [Domain.Category] {
        try await context.perform { [unowned self] in
            let request = CategoryEntity.fetchRequest()
            let modificationDate = NSSortDescriptor(key: "modificationDate", ascending: isAscending)
            let creationDate = NSSortDescriptor(key: "creationDate", ascending: isAscending)
            request.sortDescriptors = [modificationDate, creationDate]
            request.predicate = categoryHasMemo(memo: memo)
            return try self.context.fetch(request).map { $0.toDomain() }
        }
    }
    
    func searchCategory(_ searchText: String, inOrderOf orderCriterion: CategoryProperties, isAscending: Bool) async throws -> [Domain.Category] {
        try await context.perform { [unowned self] in
            let request = CategoryEntity.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: orderCriterion.rawValue, ascending: isAscending)
            request.sortDescriptors = [sortDescriptor]
            request.predicate = categoryNameContains(searchText: searchText)
            return try self.context.fetch(request).map { $0.toDomain() }
        }
    }
    
    func changeCategoryName(_ category: Domain.Category, newName: String) async throws {
        let allCategoryNames = try await getAllCategories(inOrderOf: .modificationDate, isAscending: false).map(\.name)
        guard !allCategoryNames.contains(newName) else {
            throw CoreDataError.duplicateCategoryDetected
        }
        try await context.perform { [unowned self] in
            let categoryEntity = try fetchCategoryEntity(id: category.id)
            categoryEntity.name = newName
            try context.save()
        }
        categoryUpdatedSubject.send(.update(content: .name(categoryIDs: [category.id])))
    }

    func deleteCategory(_ category: Domain.Category) async throws {
        try await context.perform { [unowned self] in
            let categoryEntity = try fetchCategoryEntity(id: category.id)
            context.delete(categoryEntity)
            try context.save()
        }
        categoryUpdatedSubject.send(.delete)
    }
    
    func memoCount(of category: Domain.Category) async throws -> Int {
        try await context.perform { [unowned self] in
            let categoryEntity = try fetchCategoryEntity(id: category.id)
            return categoryEntity.memoSet.count
        }
    }
    
    func updateModificationDate(of category: Domain.Category) async throws {
        try await context.perform { [unowned self] in
            let categoryEntity = try fetchCategoryEntity(id: category.id)
            categoryEntity.modificationDate = .now
            try context.save()
        }
        categoryUpdatedSubject.send(.update(content: .modificationDate(categoryIDs: [category.id])))
    }
    
}
