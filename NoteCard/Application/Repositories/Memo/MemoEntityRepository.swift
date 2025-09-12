//
//  MemoEntityRepository.swift
//  NoteCard
//
//  Created by 김민성 on 8/20/25.
//

import Combine
import CoreData
import Foundation

enum MemoEntityError: LocalizedError {
    
    case memoNotFound(id: UUID)
    case duplicateMemoDetected
    
    var errorDescription: String? {
        switch self {
        case .memoNotFound(let id):
            "메모를 찾을 수 없습니다. UUID: \(id)"
        case .duplicateMemoDetected:
            "같은 ID의 메모가 2개 이상 발견되었습니다. 조치 필요."
        }
    }
    
}

actor MemoEntityRepository: MemoRepository {
    
    static let shared = MemoEntityRepository()
    private init() { }
    
    private let context = CoreDataStack.shared.backgroundContext
    
    @UserDefault<String>(key: .orderCriterion, defaultValue: OrderCriterion.modificationDate.rawValue)
    private var orderCriterion: String
    
    @UserDefault<Bool>(key: .isOrderAscending, defaultValue: false)
    private var isOrderAscending: Bool
    
    // MARK: - Predicates
    
    private let isFavorite = NSPredicate(format: "isFavorite == true")
    private let notDeleted = NSPredicate(format: "isInTrash == false")
    private let deleted = NSPredicate(format: "isInTrash == true")
    
    private func memoIDEquals(to id: UUID) -> NSPredicate {
        return NSPredicate(format: "memoID == %@", id as CVarArg)
    }
    private func titleContains(searchText: String) -> NSPredicate {
        return NSPredicate(format: "memoTitle CONTAINS[c] %@", searchText)
    }
    private func memoTextContains(searchText: String) -> NSPredicate {
        return NSPredicate(format: "memoText CONTAINS[c] %@", searchText)
    }
    /// `category` 인자가 `nil`인 경우, 카테고리가 없는 데이터를 가져옴.
    private func memoHasCategory(_ category: Category?) -> NSPredicate {
        if let category {
            return NSPredicate(format: "ANY categories.name == %@", category.name as CVarArg)
        } else {
            return NSPredicate(format: "categories.@count == 0")
        }
    }
    
}


// MARK: - CREATE
extension MemoEntityRepository {
    
    func createNewMemo() async throws -> Memo {
        try await context.perform { [unowned self] in
            let newMemoEntity = MemoEntity(context: self.context)
            try self.context.save()
            return newMemoEntity.toDomain()
        }
    }
    
}


// MARK: - READ
extension MemoEntityRepository {
    
    func fetchMemoEntity(id: UUID) throws -> MemoEntity {
        let request = MemoEntity.fetchRequest()
        request.predicate = NSCompoundPredicate(
            type: .and,
            subpredicates: [memoIDEquals(to: id), notDeleted]
        )
//        request.predicate = NSPredicate(format: "memoID == %@ && isInTrash == false", id as CVarArg)
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
    
    func getMemo(id: UUID) async throws -> Memo {
        try await context.perform { [unowned self] in
            try fetchMemoEntity(id: id).toDomain()
        }
    }
    
    func getAllMemos() async throws -> [Memo]  {
        try await context.perform { [unowned self] in
            let request = MemoEntity.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: self.orderCriterion, ascending: self.isOrderAscending)
            request.sortDescriptors = [sortDescriptor]
            return try self.context.fetch(request).map { $0.toDomain() }
        }
    }
    
    /// `category`에 `nil`이 할당될 경우, 아무런 카테고리에도 속하지 않은 메모들을 반환
    func getAllMemos(inCategory category: Category?) async throws -> [Memo] {
        try await context.perform { [unowned self] in
            let request = MemoEntity.fetchRequest()
            
            let sortDescriptor = NSSortDescriptor(key: self.orderCriterion, ascending: self.isOrderAscending)
            request.sortDescriptors = [sortDescriptor]
            
            let subPredicates = [memoHasCategory(category), notDeleted]
            request.predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicates)
            
            return try self.context.fetch(request).map { $0.toDomain() }
        }
    }
    
    func getAllMemosInTrash() async throws -> [Memo] {
        try await context.perform { [unowned self] in
            let request = MemoEntity.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: self.orderCriterion, ascending: self.isOrderAscending)
            request.sortDescriptors = [sortDescriptor]
            request.predicate = deleted
            return try self.context.fetch(request).map { $0.toDomain() }
        }
    }
    
    /// `category`에 `nil`이 할당될 경우, 전체 메모 목록에서 검색한 결과를 반환
    ///
    /// - Note: `getAllMemos(inCategory:)`과 `category`가 `nil`인 경우의 로직이 다름.
    func searchMemo(searchText: String, inCategory category: Category? = nil) async throws -> [Memo] {
        try await context.perform { [unowned self] in
            let request = MemoEntity.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: self.orderCriterion, ascending: self.isOrderAscending)
            request.sortDescriptors = [sortDescriptor]
            guard !searchText.isEmpty else {
                return []
            }
            
            let searchQueryPredicate = NSCompoundPredicate(
                type: .or,
                subpredicates: [titleContains(searchText: searchText), memoTextContains(searchText: searchText)]
            )
            
            if let category {
                request.predicate = NSCompoundPredicate(
                    andPredicateWithSubpredicates: [searchQueryPredicate, memoHasCategory(category), notDeleted]
                )
            } else {
                request.predicate = NSCompoundPredicate(
                    andPredicateWithSubpredicates: [searchQueryPredicate, notDeleted]
                )
            }
            
            return try self.context.fetch(request).map { $0.toDomain() }
        }
    }
    
    func getFavoriteMemos() async throws -> [Memo] {
        try await context.perform { [unowned self] in
            let request = MemoEntity.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: self.orderCriterion, ascending: self.isOrderAscending)
            request.sortDescriptors = [sortDescriptor]
            request.predicate = NSCompoundPredicate(
                type: .and,
                subpredicates: [isFavorite, notDeleted]
            )
            return try self.context.fetch(request).map { $0.toDomain() }
        }
    }
    
}


// MARK: - DELETE(Soft)
extension MemoEntityRepository {
    
    func moveToTrash(_ memo: Memo) async throws {
        try await context.perform { [unowned self] in
            let memoEntityToTrash = try self.fetchMemoEntity(id: memo.memoID)
            memoEntityToTrash.isFavorite = false
            memoEntityToTrash.isInTrash = true
            memoEntityToTrash.deletedDate = .now
            memoEntityToTrash.removeFromCategories(memoEntityToTrash.categories)
            try self.context.save()
        }
    }
    
    func moveToTrash(_ memos: [Memo]) async throws {
        try await context.perform { [unowned self] in
            for memo in memos {
                let memoEntityToTrash = try self.fetchMemoEntity(id: memo.memoID)
                memoEntityToTrash.isFavorite = false
                memoEntityToTrash.isInTrash = true
                memoEntityToTrash.deletedDate = .now
                memoEntityToTrash.removeFromCategories(memoEntityToTrash.categories)
            }
            try self.context.save()
        }
    }
    
}


// MARK: - ⚠️ DELETE(Hard)
extension MemoEntityRepository {
    
    func deleteMemo(_ memo: Memo) async throws {
        try await context.perform { [unowned self] in
            let memoEntityToDelete = try self.fetchMemoEntity(id: memo.memoID)
            // FileManager에서 메모 디렉토리(및 이미지들) 삭제
            let memoDirectoryURL = try ImageFileHandler.getDirectory(for: memo.memoID)
            try FileManager.default.removeItem(at: memoDirectoryURL)
            // 코어데이터에서 ImageEntity들 삭제 (FileManager에서 이미지 파일 삭제 후에 실행 필수)
            if let images = memoEntityToDelete.images as? Set<ImageEntity> {
                images.forEach { self.context.delete($0) }
            }
            // 메모 삭제 (memoEntity들로부터 삭제되는 건 Delete Rule이 Nullify라서 자동으로 참조가 제거됨.)
            self.context.delete(memoEntityToDelete)
            try self.context.save()
        }
    }
    
    func deleteMemos(_ memos: [Memo]) async throws {
        try await context.perform { [unowned self] in
            for memo in memos {
                let memoEntityToDelete = try self.fetchMemoEntity(id: memo.memoID)
                // FileManager에서 메모 디렉토리(및 이미지들) 삭제
                let memoDirectoryURL = try ImageFileHandler.getDirectory(for: memo.memoID)
                try FileManager.default.removeItem(at: memoDirectoryURL)
                // 코어데이터에서 ImageEntity들 삭제 (FileManager에서 이미지 파일 삭제 후에 실행 필수)
                if let images = memoEntityToDelete.images as? Set<ImageEntity> {
                    images.forEach { self.context.delete($0) }
                }
                // 메모 삭제 (memoEntity들로부터 삭제되는 건 Delete Rule이 Nullify라서 자동으로 참조가 제거됨.)
                self.context.delete(memoEntityToDelete)
            }
            try self.context.save()
        }
    }
    
}


// MARK: - RESTORING
extension MemoEntityRepository {
    
    func restore(_ memo: Memo) async throws {
        try await context.perform { [unowned self] in
            let memoEntityToRestore = try self.fetchMemoEntity(id: memo.memoID)
            memoEntityToRestore.isInTrash = false
            memoEntityToRestore.deletedDate = nil
            try self.context.save()
        }
    }
    
    func restore(_ memos: [Memo]) async throws {
        try await context.perform { [unowned self] in
            for memo in memos {
                let memoEntityToRestore = try self.fetchMemoEntity(id: memo.memoID)
                memoEntityToRestore.isInTrash = false
                memoEntityToRestore.deletedDate = nil
            }
            try self.context.save()
        }
    }
    
}


// MARK: - UPDATE
extension MemoEntityRepository {
    
    func replaceCategories(memoID: UUID, newCategories: Set<Category>) async throws {
        try await context.perform { [unowned self] in
            let memoEntity = try self.fetchMemoEntity(id: memoID)
            let oldCategories = memoEntity.categories
            let newNSSet = Set(newCategories.map { $0.toEntity(in: self.context) }) as NSSet
            memoEntity.removeFromCategories(oldCategories)
            memoEntity.addToCategories(newNSSet)
            try self.context.save()
        }
    }
    
    func replaceCategories(memoIDs: [UUID], newCategories: Set<Category>) async throws {
        try await context.perform { [unowned self] in
            for memoID in memoIDs {
                let memoEntity = try self.fetchMemoEntity(id: memoID)
                let oldCategories = memoEntity.categories
                let newNSSet = Set(newCategories.map { $0.toEntity(in: self.context) }) as NSSet
                memoEntity.removeFromCategories(oldCategories)
                memoEntity.addToCategories(newNSSet)
            }
            try self.context.save()
        }
    }
    
    func setFavorite(_ memo: Memo, to value: Bool) async throws {
        try await context.perform { [unowned self] in
            let memoEntity = try self.fetchMemoEntity(id: memo.memoID)
            memoEntity.isFavorite = value
            try self.context.save()
        }
    }
    
    func setFavorite(_ memos: [Memo], to value: Bool) async throws {
        try await context.perform { [unowned self] in
            for memo in memos {
                let memoEntity = try self.fetchMemoEntity(id: memo.memoID)
                memoEntity.isFavorite = value
            }
            try context.save()
        }
    }
    
    func updateMemoContent(_ memo: Memo, newTitle: String? = nil, newMemoText: String? = nil) async throws {
        try await context.perform { [unowned self] in
            let memoEntity = try self.fetchMemoEntity(id: memo.memoID)
            if let newTitle {
                memoEntity.memoTitle = newTitle
            }
            if let newMemoText {
                memoEntity.memoText = newMemoText
            }
            try self.context.save()
        }
    }
    
}
