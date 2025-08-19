//
//  CategoryEntityManager.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit
import CoreData


enum CategoryNameError: Error {
    case duplicatedNameError
}


final class CategoryEntityManager {
    
    static let shared = CategoryEntityManager()
    private init() { }
    
    let fileManager = FileManager.default
    let context = CoreDataStack.shared.persistentContainer.viewContext

    weak var appDelegate = UIApplication.shared.delegate as? AppDelegate
//    lazy var context = appDelegate?.persistentContainer.viewContext
//    weak var context: NSManagedObjectContext? {
//        guard let appDelegate else {fatalError() }
//        return appDelegate.persistentContainer.viewContext
//    }

    let entityName: String = "CategoryEntity"
    
    
    /*

     name: String?
     savedDate: Date?
     creationDate: Date?
     memoEntity: MemoEntity?

     */
    
    
    
    func createCategoryEntity(withName name: String) throws {
        
        let trimmedName = name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard trimmedName != "" else {
            print("빈 문자열임")
            return
        }
        
        let categoryNamesArray = self.getCategoryEntities(inOrderOf: .creationDate, isAscending: true).map({ $0.name })
        guard categoryNamesArray.contains(trimmedName) == false else {
            throw CategoryNameError.duplicatedNameError
        }
        guard let entityDescription = NSEntityDescription.entity(forEntityName: self.entityName, in: context) else { return }
        guard let managedObject = NSManagedObject(entity: entityDescription, insertInto: context) as? CategoryEntity else { return }
        
//        let documentURL = fileManager.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)[0]
//        print(documentURL)
//        let newCategoryDirectoryURL = documentURL.appending(path: trimmedName, directoryHint: URL.DirectoryHint.inferFromPath)
//        //let newCategoryDirectoryURL = documentURL.appendingPathComponent(trimmedName)
//        print(newCategoryDirectoryURL)
//        
//        do {
//            try fileManager.createDirectory(at: newCategoryDirectoryURL, withIntermediateDirectories: false)
//        } catch let error {
//            print(error.localizedDescription)
//        }
        
        managedObject.name = trimmedName
        let date = Date()
        managedObject.creationDate = date
        managedObject.modificationDate = date
//        managedObject.memoSet = NSSet()  //Instance will be immediately deallocated because property 'memoSet' is 'weak'
        
        CoreDataStack.shared.saveContext()
    }
    
    
    
    func getCategoryEntities(memo memoEntity: MemoEntity? = nil, inOrderOf criterion: CategoryProperties, isAscending: Bool) -> [CategoryEntity] {
        
        var categoryEntityArray: [CategoryEntity] = []
//        if let context = self.context {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        let dataOrder = NSSortDescriptor(key: criterion.rawValue, ascending: isAscending)
        request.sortDescriptors = [dataOrder]
        
        do {
            if let fetchedCategoryArray = try context.fetch(request) as? [CategoryEntity] {
                categoryEntityArray = fetchedCategoryArray
            }
        } catch {
            print("fetch request failed")
        }
//        }
        
        
        if memoEntity != nil {
            if let categories = memoEntity?.categories {
                let filteredArray = categoryEntityArray.filter { categoryEntity in
                    return categories.contains(categoryEntity)
                }
                return filteredArray
            }
            
        }
        return categoryEntityArray
    }
    
    
    func searchCategoryEntity(with searchText: String, order criterion: CategoryProperties, ascending: Bool) -> [CategoryEntity] {
        
        let searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        var searchResult: [CategoryEntity] = []
//        if let context {
        
        let request = NSFetchRequest<CategoryEntity>(entityName: self.entityName)
        let sortDescriptor = NSSortDescriptor(key: criterion.rawValue, ascending: ascending)
        request.sortDescriptors = [sortDescriptor]
        request.predicate = NSPredicate(format: "name CONTAINS[c] %@", searchText)
        
        do{
            searchResult = try context.fetch(request)
            return searchResult
        } catch {
            fatalError("categoryEntity searchResult fetching failed")
        }
//        }
//        fatalError("viewContext is nil. Maybe because appDelegate is nil. check if appDelegate is nil.")
    }
    
    
    //아래 메서드랑 둘 중에 하나로 통일
//    func changeCategoryName(ofEntity entity: CategoryEntity, newName: String) {
//        let trimmedNewName = newName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//        let documentURL = fileManager.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)[0]
//        
//        if let context = context {
//            let request = NSFetchRequest<NSManagedObject>(entityName: self.entityName)
//            request.predicate = NSPredicate(format: "name = %@", entity.name as CVarArg)
//            
//            do {
//                guard let fetchedCategoryEntityList = try context.fetch(request) as? [CategoryEntity] else { return }
//                
//                guard let oldCategoryEntity = fetchedCategoryEntityList.first else { return }
//                oldCategoryEntity.name = trimmedNewName
//                appDelegate?.saveContext()
//                
//                //이제 디렉토리 이름 바꿔줄 차례
//                
//                //새로운 path 만들어줌
//                let newNameDirectory = documentURL.appending(path: trimmedNewName, directoryHint: URL.DirectoryHint.inferFromPath)
//                //새로운 디렉토리 만들어줌
//                do {
//                    try fileManager.createDirectory(at: newNameDirectory, withIntermediateDirectories: false)
//                } catch let error {
//                    print(error.localizedDescription)
//                }
//                //기존 컨텐츠 새로운 디레토리로 이주
//                do {
//                    try fileManager.moveItem(at: entity.categoryDirectoryURL, to: newNameDirectory)
//                } catch let error {
//                    print(error.localizedDescription)
//                }
//                //기존 디렉토리 삭제
//                do {
//                    try fileManager.removeItem(at: entity.categoryDirectoryURL)
//                } catch let error {
//                    print(error.localizedDescription)
//                }
//                
//                //카테고리엔티티의 categoryDirectoryURL 속성 최신화
//                entity.categoryDirectoryURL = newNameDirectory
//                
//            } catch {
//                print("update failed")
//            }
//        }
//    }
    
    
    //위 메서드랑 하나로 통일
    func changeCategoryEntityName(ofEntity entity: CategoryEntity, newName: String) throws {
        let categoryNamesArray = self.getCategoryEntities(inOrderOf: .modificationDate, isAscending: false).map({ $0.name })
        if entity.name != newName && categoryNamesArray.contains(newName.trimmingCharacters(in: .whitespacesAndNewlines)) {
            throw CategoryNameError.duplicatedNameError
        }
        
        let request = NSFetchRequest<NSManagedObject>(entityName: self.entityName)
        request.predicate = NSPredicate(format: "name = %@", entity.name as CVarArg)
        
        do {
            guard let fetchedCategoryEntityList = try context.fetch(request) as? [CategoryEntity] else { return }
            guard let categoryEntityToChangeName = fetchedCategoryEntityList.first else { return }
            categoryEntityToChangeName.name = newName
            
            CoreDataStack.shared.saveContext()
        } catch {
            print("Category Name Update Failed")
        }
    }
    
    
    //MARK: - [Delete]
    
    /// deletes a category entity from coredata
    /// - Parameter entity: a category entity to delete from coredate
    ///
    /// this method can fetch category entity as a [CategoryEntity] type. If you want to delete a number of category entity at once, you can change this method or make similar method
    func deleteCategoryEntity(of entity: CategoryEntity) {
        
        //        if let context = context {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        
        request.predicate = NSPredicate(format: "name = %@", entity.name as CVarArg)
        
        do {
            guard let fetchedCategoryList = try context.fetch(request) as? [CategoryEntity] else { return }
            guard let entityToDelete = fetchedCategoryList.first else { return }
            
            //해당 카테고리를 참조하는 메모들에서 각 메모의 categorySet에서 카테고리 하나씩 삭제하는 작업
            //이 작업은 cotext.delete(entityToDelete) 코드 이전에 실행되어야 함.
            //categoryEntity는 처음 만들 때 memoSet속성에 값을 부여하는 과정은 없음.
            //따라서 아래 옵셔널 바인딩이 guard let ~ else { return } 의 형식이었으면
            //카테고리를 만들고 나서 메모를 추가하지 않고 카테고리를 바로 삭제할 때에는 아래 옵셔널 바인딩에서 nil이 반환될 것임.
            if let memoSet = entityToDelete.memoSet as? Set<MemoEntity> {
                memoSet.forEach { memoEntity in
                    memoEntity.removeFromCategories(entityToDelete)
                }
            }
            
            let documentURL = fileManager.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)[0]
            
            if #available(iOS 16, *) {
                let urlToDeleteEntity = documentURL.appending(path: entityToDelete.name, directoryHint: URL.DirectoryHint.inferFromPath)
                
                do { try fileManager.removeItem(at: urlToDeleteEntity) }
                catch { print(error.localizedDescription) }
                
            } else {
                let urlToDeleteEntity = documentURL.appendingPathComponent(entityToDelete.name)
                
                do { try fileManager.removeItem(at: urlToDeleteEntity) }
                catch { print(error.localizedDescription) }
                
            }
            
            
            
            context.delete(entityToDelete)
            
            CoreDataStack.shared.saveContext()
        } catch {
            print("delete failed")
        }
//        }
    }
    
    
    
    func memoCounted(of category: CategoryEntity) -> Int {
        
//        if let context {
        let request = NSFetchRequest<MemoEntity>(entityName: "MemoEntity")
        request.predicate = NSPredicate(format: "ANY categories == %@", category as CVarArg)
        
        do {
            let memoEntityArray = try context.fetch(request)
            return memoEntityArray.count
        } catch {
            fatalError(error.localizedDescription)
        }
//        } else {
//            fatalError("context is nil.")
//        }
    }
    
    
    
    //MARK: - [Search]
    //이런 메서드는 굳이 필요 없지 않을까...?
//    func searchEntity(nameOf name: String?) -> CategoryEntity? {
//        guard let name = name else { return nil }
//
//        if let context = context {
//            let request = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
//            request.predicate = NSPredicate(format: "name = %@", name as CVarArg)
//            
//            do {
//                if let fetchedCategoryEntityList = try context.fetch(request) as? [CategoryEntity] {
//                    if let fetchedCategoryEntity = fetchedCategoryEntityList.first {
//                        return fetchedCategoryEntity
//                    } else {
//                        return nil
//                    }
//                } else {
//                    return nil
//                }
//            } catch {
//                print("search failed")
//                return nil
//            }
//        } else {
//            return nil
//        }
//    }
}

