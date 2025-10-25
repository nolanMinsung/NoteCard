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
    
    enum MemoUpdateType: Equatable {
        enum UpdateContent {
            case favorite
            case titleText
            case category
        }
        
        case create
        case trash
        case delete
        case restore
        case update(content: UpdateContent)
    }
    
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
    
    // MARK: - Subjects
    
    nonisolated private let memoUpdatedSubject = PassthroughSubject<MemoUpdateType, Never>()
    nonisolated var memoUpdatedPublisher: AnyPublisher<MemoUpdateType, Never> {
        memoUpdatedSubject.eraseToAnyPublisher()
    }
}


// MARK: - CREATE
extension MemoEntityRepository {
    
    func createNewMemo() async throws -> Memo {
        let createdMemo = try await context.perform { [unowned self] in
            let newMemoEntity = MemoEntity(context: self.context)
            try self.context.save()
            return newMemoEntity.toDomain()
        }
        memoUpdatedSubject.send(.create)
        return createdMemo
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
    
    func fetchTrashMemoEntity(id: UUID) throws -> MemoEntity {
        let request = MemoEntity.fetchRequest()
        request.predicate = NSCompoundPredicate(
            type: .and,
            subpredicates: [memoIDEquals(to: id), deleted]
        )
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
            request.predicate = notDeleted
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
        memoUpdatedSubject.send((.trash))
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
        memoUpdatedSubject.send(.trash)
    }
    
}


// MARK: - ⚠️ DELETE(Hard)
extension MemoEntityRepository {
    
    func deleteMemo(_ memo: Memo) async throws {
        try await context.perform { [unowned self] in
            let memoEntityToDelete = try self.fetchTrashMemoEntity(id: memo.memoID)
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
        memoUpdatedSubject.send(.delete)
    }
    
    func deleteMemos(_ memos: [Memo]) async throws {
        try await context.perform { [unowned self] in
            for memo in memos {
                let memoEntityToDelete = try self.fetchTrashMemoEntity(id: memo.memoID)
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
        memoUpdatedSubject.send(.delete)
    }
    
}


// MARK: - RESTORING
extension MemoEntityRepository {
    
    func restore(_ memo: Memo) async throws {
        try await context.perform { [unowned self] in
            let memoEntityToRestore = try self.fetchTrashMemoEntity(id: memo.memoID)
            memoEntityToRestore.isInTrash = false
            memoEntityToRestore.deletedDate = nil
            try self.context.save()
        }
        memoUpdatedSubject.send(.restore)
    }
    
    func restore(_ memos: [Memo]) async throws {
        try await context.perform { [unowned self] in
            for memo in memos {
                let memoEntityToRestore = try self.fetchTrashMemoEntity(id: memo.memoID)
                memoEntityToRestore.isInTrash = false
                memoEntityToRestore.deletedDate = nil
            }
            try self.context.save()
        }
        memoUpdatedSubject.send(.restore)
    }
    
}


// MARK: - UPDATE
extension MemoEntityRepository {
    
    func replaceCategories(to memo: Memo, newCategories: Set<Category>) async throws {
        try await context.perform { [unowned self] in
            let memoEntity = try self.fetchMemoEntity(id: memo.memoID)
            let oldCategories = memoEntity.categories
            let newCategorySet: NSSet = Set(newCategories.map { $0.toEntity(in: self.context) }) as NSSet
            memoEntity.removeFromCategories(oldCategories)
            memoEntity.addToCategories(newCategorySet)
            try self.context.save()
        }
        memoUpdatedSubject.send(.update(content: .category))
    }
    
    func replaceCategories(to memos: [Memo], newCategories: Set<Category>) async throws {
        try await context.perform { [unowned self] in
            for memo in memos {
                let memoEntity = try self.fetchMemoEntity(id: memo.memoID)
                let oldCategories = memoEntity.categories
                let newCategorySet: NSSet = Set(newCategories.map { $0.toEntity(in: self.context) }) as NSSet
                memoEntity.removeFromCategories(oldCategories)
                memoEntity.addToCategories(newCategorySet)
            }
            try self.context.save()
        }
        memoUpdatedSubject.send(.update(content: .category))
    }
    
    func addCategories(to memo: Memo, newCategories: Set<Category>) async throws {
        try await context.perform { [unowned self] in
            let memoEntity = try self.fetchMemoEntity(id: memo.memoID)
            let newCategorySet: NSSet = Set(newCategories.map { $0.toEntity(in: self.context) }) as NSSet
            memoEntity.addToCategories(newCategorySet)
            try self.context.save()
        }
        memoUpdatedSubject.send(.update(content: .category))
    }
    
    func addCategories(to memos: [Memo], newCategories: Set<Category>) async throws {
        try await context.perform { [unowned self] in
            for memo in memos {
                let memoEntity = try self.fetchMemoEntity(id: memo.memoID)
                let newCategorySet: NSSet = Set(newCategories.map { $0.toEntity(in: self.context) }) as NSSet
                memoEntity.addToCategories(newCategorySet)
            }
            try self.context.save()
        }
        memoUpdatedSubject.send(.update(content: .category))
    }
    
    func removeCategories(to memo: Memo, newCategories: Set<Category>) async throws {
        try await context.perform { [unowned self] in
            let memoEntity = try self.fetchMemoEntity(id: memo.memoID)
            let newCategorySet: NSSet = Set(newCategories.map { $0.toEntity(in: self.context) }) as NSSet
            memoEntity.removeFromCategories(newCategorySet)
            try self.context.save()
        }
        memoUpdatedSubject.send(.update(content: .category))
    }
    
    func removeCategories(to memos: [Memo], newCategories: Set<Category>) async throws {
        try await context.perform { [unowned self] in
            for memo in memos {
                let memoEntity = try self.fetchMemoEntity(id: memo.memoID)
                let newCategorySet: NSSet = Set(newCategories.map { $0.toEntity(in: self.context) }) as NSSet
                memoEntity.removeFromCategories(newCategorySet)
            }
            try self.context.save()
        }
        memoUpdatedSubject.send(.update(content: .category))
    }
    
    func setFavorite(_ memo: Memo, to value: Bool) async throws {
        try await context.perform { [unowned self] in
            let memoEntity = try self.fetchMemoEntity(id: memo.memoID)
            memoEntity.isFavorite = value
            try self.context.save()
        }
        memoUpdatedSubject.send(.update(content: .favorite))
    }
    
    func setFavorite(_ memos: [Memo], to value: Bool) async throws {
        try await context.perform { [unowned self] in
            for memo in memos {
                let memoEntity = try self.fetchMemoEntity(id: memo.memoID)
                memoEntity.isFavorite = value
            }
            try context.save()
        }
        memoUpdatedSubject.send(.update(content: .favorite))
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
            memoEntity.modificationDate = .now
            try self.context.save()
        }
        memoUpdatedSubject.send(.update(content: .titleText))
    }
    
}
