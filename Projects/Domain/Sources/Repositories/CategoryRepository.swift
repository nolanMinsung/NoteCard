//
//  CategoryRepository.swift
//  NoteCard
//
//  Created by 김민성 on 8/28/25.
//

import Combine
import Foundation
import Shared

public protocol CategoryRepository: Sendable {

    var categoryUpdatedPublisher: AnyPublisher<CategoryUpdateType, Never> { get }

    func create(name: String) async throws

    func getCategory(id: UUID) async throws -> Category

    func getAllCategories(
        inOrderOf orderCriterion: CategoryProperties,
        isAscending: Bool
    ) async throws -> [Category]
    
    func getAllCategories(
        ofMemo memo: Memo,
        inOrderOf orderCriterion: CategoryProperties,
        isAscending: Bool
    ) async throws -> [Category]
    
    func searchCategory(
        _ searchText: String,
        inOrderOf orderCriterion: CategoryProperties,
        isAscending: Bool
    ) async throws -> [Category]
    
    func changeCategoryName(_ category: Category, newName: String) async throws
    
    func deleteCategory(_ category: Category) async throws
    
    func memoCount(of category: Category) async throws -> Int
    
    func updateModificationDate(of category: Category) async throws
    
}
