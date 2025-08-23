//
//  MemoEntityRepository.swift
//  NoteCard
//
//  Created by 김민성 on 8/20/25.
//

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
    
    func createNewMemo() throws -> MemoEntity {
        try context.performAndWait {
            let newMemoEntity = MemoEntity(context: self.context)
            try self.context.save()
            return newMemoEntity
        }
    }
    
}


// MARK: - READ
extension MemoEntityRepository {
    
    func getMemo(id: UUID) throws -> MemoEntity {
        try context.performAndWait {
            let request = MemoEntity.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: self.orderCriterion, ascending: self.isOrderAscending)
            request.sortDescriptors = [sortDescriptor]
            request.predicate = NSPredicate(
                format: "memoID == %@ && isInTrash == false",
                id as CVarArg,
            )
            let foundMemo =  try self.context.fetch(request)
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
    
    func getAllMemo() throws -> [MemoEntity]  {
        try context.performAndWait {
            let request = MemoEntity.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: self.orderCriterion, ascending: self.isOrderAscending)
            request.sortDescriptors = [sortDescriptor]
            return try self.context.fetch(request)
        }
    }
    
    func getFilteredMemo(inCategory category: CategoryEntity) throws -> [MemoEntity] {
        try context.performAndWait {
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
    
    func getMemoInTrash() throws -> [MemoEntity] {
        try context.performAndWait {
            let request = MemoEntity.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: self.orderCriterion, ascending: self.isOrderAscending)
            request.sortDescriptors = [sortDescriptor]
            request.predicate = NSPredicate(format: "isInTrash == true")
            return try self.context.fetch(request)
        }
    }
    
    func searchMemo(searchText: String, inCategory: CategoryEntity? = nil) throws -> [MemoEntity] {
        try context.performAndWait {
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
    
    func getFavoriteMemo() throws -> [MemoEntity] {
        try context.performAndWait {
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
    
    func moveToTrash(_ memoEntity: MemoEntity) throws {
        try context.performAndWait {
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


// MARK: - ⚠️ DELETE(Hard)
extension MemoEntityRepository {
    
    func deleteMemo(_ memoEntity: MemoEntity) throws {
        try context.performAndWait {
            // 카테고리들로부터 메모를 삭제
            let categories = memoEntity.categories
            guard let images = memoEntity.images as? Set<ImageEntity> else { return }
            memoEntity.removeFromCategories(categories)
            
            // FileManager에서 메모 디렉토리(밎 이미지들) 삭제
            let memoDirectoryURL = try self.getMemoDirectoryURL(of: memoEntity)
            try FileManager.default.removeItem(at: memoDirectoryURL)
            
            // 코어데이터에서 imageEntity들 삭제
            images.forEach { self.context.delete($0) }
            
            // 코어데이터에서 memoEntity 삭제
            self.context.delete(memoEntity)
            try self.context.save()
        }
    }
    
}


// MARK: - RESTORING
extension MemoEntityRepository {
    
    func restore(_ memoEntity: MemoEntity) throws {
        try context.performAndWait {
            memoEntity.isInTrash = false
            memoEntity.deletedDate = nil
            try self.context.save()
        }
    }
    
}


// MARK: - UPDATE
extension MemoEntityRepository {
    
    func replaceCategories(_ memoEntity: MemoEntity, newCategories: Set<CategoryEntity>) throws {
        try context.performAndWait {
            let oldCategories = memoEntity.categories
            let newNSSet = newCategories as NSSet
            memoEntity.removeFromCategories(oldCategories)
            memoEntity.addToCategories(newNSSet)
            try self.context.save()
        }
    }
    
    func setFavorite(_ memoEntity: MemoEntity, to value: Bool) throws {
        try context.performAndWait {
            memoEntity.isFavorite = value
            try self.context.save()
        }
    }
    
}
