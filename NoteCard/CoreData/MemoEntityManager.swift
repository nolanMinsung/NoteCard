//
//  MemoEntityManager.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit
import CoreData

//코어데이터를 관리하는 매니저입니다
final class MemoEntityManager {
    
    let fileManager = FileManager.default
    let imageEntityManager = ImageEntityManager.shared
    static let shared = MemoEntityManager()
    private init() {}
    
    let categoryManager = CategoryEntityManager.shared
    
    weak var appDelegate = UIApplication.shared.delegate as? AppDelegate
//    lazy var context = appDelegate?.persistentContainer.viewContext
//    weak var context: NSManagedObjectContext? {
//        guard let appDelegate else { fatalError() }
//        return appDelegate.persistentContainer.viewContext
//    }
    
    let entityName: String = "MemoEntity"
    
    // MARK: - Create
    func createMemoEntity(
        memoTitleText: String,
        memoText: String,
        categorySet: Set<CategoryEntity> = Set<CategoryEntity>(),
        image: [ImageEntity]? = nil
    ) -> MemoEntity? {
        guard let context = self.appDelegate?.persistentContainer.viewContext else { fatalError() }
        guard let entityDescription = NSEntityDescription.entity(forEntityName: self.entityName, in: context) else { return nil }
        guard let newMemoEntity = NSManagedObject(entity: entityDescription, insertInto: context) as? MemoEntity else { return nil }
        newMemoEntity.memoID = UUID()
        newMemoEntity.memoTitle = memoTitleText
        newMemoEntity.memoText = memoText
        let currentDate = Date()
        newMemoEntity.creationDate = currentDate
        newMemoEntity.modificationDate = currentDate
        newMemoEntity.deletedDate = nil
        newMemoEntity.isFavorite = false
        newMemoEntity.isInTrash = false
        newMemoEntity.images = NSSet()
        
        // 카테고리에 추가
        for category in categorySet {
            category.addToMemoSet(newMemoEntity)
//            여기서 category.modificationDate를 최신화하면 메모 만들다 취소했을 때에도 카테고리 목록 순서가 바뀔 수 있기 때문에
//            category의 modificationDate를 바꾸는 일은 작성된 메모가 실제로 저장되는 시점에서 진행.
//            category.modificationDate = Date()
            newMemoEntity.addToCategories(category)
        }
        
        appDelegate?.saveContext()
        print("코어데이터에 memoEntity 저장됨")
        
        
        //폴더 생성
        let documentURL = fileManager.urls(
            for: FileManager.SearchPathDirectory.documentDirectory,
            in: FileManager.SearchPathDomainMask.userDomainMask)[0]
        let newMemoDirectoryURL: URL
        if #available(iOS 16, *) {
            newMemoDirectoryURL = documentURL.appending(path: newMemoEntity.memoID.uuidString, directoryHint: URL.DirectoryHint.inferFromPath)
        } else {
            newMemoDirectoryURL = documentURL.appendingPathComponent(newMemoEntity.memoID.uuidString)
        }
        //경로 추가함
        
        //방금 만든 새로운 path에 새로운 디렉토리 만들어줌
        do { try fileManager.createDirectory(at: newMemoDirectoryURL, withIntermediateDirectories: false) }
        catch { fatalError("creating Directory of memo failed") }
        
        return newMemoEntity
        
    }
    
    
    // MARK: - Read
    func getMemoEntitiesFromCoreData() -> [MemoEntity] {
        
        guard let orderCriterion = UserDefaults.standard.string(
            forKey: UserDefaultsKeys.orderCriterion.rawValue
        ) else {
            fatalError()
        }
        guard let isAscending = UserDefaults.standard.value(
            forKey: UserDefaultsKeys.isOrderAscending.rawValue
        ) as? Bool else {
            fatalError()
        }
        
        var memoEntityList: [MemoEntity] = []
        
        guard let context = self.appDelegate?.persistentContainer.viewContext else { fatalError() }
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        let dataOrder = NSSortDescriptor(key: orderCriterion, ascending: isAscending)
        request.sortDescriptors = [dataOrder]
        request.predicate = NSPredicate(format: "isInTrash == false")
        
        do {
            if let fetchedMemoTextList = try context.fetch(request) as? [MemoEntity] {
                memoEntityList = fetchedMemoTextList
            }
        } catch {
            print("fetch request failed")
        }
        return memoEntityList
    }
    
    // MARK: - Filter
    func getSpecificMemoEntitiesFromCoreData(inCategory category: CategoryEntity?) -> [MemoEntity] {
        
        guard let orderCriterion = UserDefaults.standard.string(forKey: UserDefaultsKeys.orderCriterion.rawValue) else { fatalError() }
        guard let isAscending = UserDefaults.standard.value(forKey: UserDefaultsKeys.isOrderAscending.rawValue) as? Bool else { fatalError() }
        
        
        var memoEntitiesArray: [MemoEntity] = []
        //guard let categoryName = category.name else { return [] }
        
//        if let context = self.context {
        guard let context = self.appDelegate?.persistentContainer.viewContext else { fatalError() }
            let request = NSFetchRequest<NSManagedObject>(entityName: self.entityName)
//            let memoOrder = NSSortDescriptor(key: criterion.rawValue, ascending: ascending)
            let memoOrder = NSSortDescriptor(key: orderCriterion, ascending: isAscending)
            request.sortDescriptors = [memoOrder]
            
            if let category {
                request.predicate = NSPredicate(format: "ANY categories == %@ && isInTrash == false", category as CVarArg)
            } else {
                request.predicate = NSPredicate(format: "categories.@count == 0 && isInTrash == false") //메모엔티티가 참조하는 카테고리의 수가 0인 메모엔티티들을 반환
            }
            
            
            do {
                if let fetchedMemoEntitiesList = try context.fetch(request) as? [MemoEntity] {
                    memoEntitiesArray = fetchedMemoEntitiesList
                }
            } catch {
                print("fetch request failed")
            }
        
        return memoEntitiesArray
    }
    
    // MARK: - Read From Trash
    func getMemoEntitiesInTrash() -> [MemoEntity] {
        
//        guard let orderCriterion = UserDefaults.standard.string(forKey: KeysForUserDefaults.orderCriterion.rawValue) else { fatalError() }
        guard let isAscending = UserDefaults.standard.value(forKey: UserDefaultsKeys.isOrderAscending.rawValue) as? Bool else { fatalError() }
        
        var memoEntitiesArray: [MemoEntity] = []
        
//        if let context = self.context {
        guard let context = self.appDelegate?.persistentContainer.viewContext else { fatalError() }
            let request = NSFetchRequest<MemoEntity>(entityName: self.entityName)
//            let memoOrder = NSSortDescriptor(key: criterion.rawValue, ascending: ascending)
            let memoOrder = NSSortDescriptor(key: "deletedDate", ascending: isAscending)
            request.sortDescriptors = [memoOrder]
            request.predicate = NSPredicate(format: "isInTrash == true")
            
            do {
                let fetchedMemoEntitiesList = try context.fetch(request)
                memoEntitiesArray = fetchedMemoEntitiesList
                
            } catch {
                print("fetch request failed")
            }
//        }
        return memoEntitiesArray
    }
    
    
    // MARK: - Memo Searching
    
    
    /// 검색어를 이용해서 특정 메모엔티티만 불러오는 메서드
    /// - Parameters:
    ///   - searchText: 검색할 단어. 메모의 제목 또는 메모 텍스트에 searchText가 포함되면(대소문 구분 없음) 반환값의 요소에 포함됨.
    ///   - criterion: 반환될 배열의 순서 기준
    ///   - ascending: 오름차순 여부
    ///   - category: 특정 카테고리의 메모만 불러오고 싶을 경우, 이 매개변수에 값을 할당하면 됨. nil을 넣을 경우, 전제 메모엔티티에서 검색
    /// - Returns: 검색된 메모엔티티를 요소로 갖는 배열을 반환
    /// 원래는 searchText에 아무것도 안 넣으면 모든 메모를 반환해야 하는게 직관적인데, nspredicate format에서는 빈칸은 CONTAINS에서 결과가 true로 나오지 않나보다.
    /// 이 부분은 searchText.isEmpty 메서드를 이용해서 searchText에 빈칸을 넣어도 전부 검색되게 구현함.
    func searchMemoEntity(with searchText: String, category: CategoryEntity? = nil) -> [MemoEntity] {
        
        guard let orderCriterion = UserDefaults.standard.string(forKey: UserDefaultsKeys.orderCriterion.rawValue) else { fatalError() }
        guard let isAscending = UserDefaults.standard.value(forKey: UserDefaultsKeys.isOrderAscending.rawValue) as? Bool else { fatalError() }
        
        
//        let searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        var searchResult: [MemoEntity] = []
//        if let context {
        guard let context = self.appDelegate?.persistentContainer.viewContext else { fatalError() }
            let request = NSFetchRequest<MemoEntity>(entityName: self.entityName)
//            let sortDescriptor = NSSortDescriptor(key: criterion.rawValue, ascending: ascending)
            let sortDescriptor = NSSortDescriptor(key: orderCriterion, ascending: isAscending)
            request.sortDescriptors = [sortDescriptor]
            if !searchText.isEmpty {
                request.predicate = NSPredicate(format: "(memoTitle CONTAINS[c] %@ || memoText CONTAINS[c] %@) && isInTrash == false", searchText, searchText)
            } else {
                request.predicate = NSPredicate(format: "isInTrash == false")
            }
            
            do {
                let memoEntitySearchResult = try context.fetch(request)
                searchResult = memoEntitySearchResult
                return searchResult
            } catch {
                fatalError("memoEntity searchResult fetching failed")
            }
//        }
//        fatalError("viewContext is nil. Maybe because appDelegate is nil. check if appDelegate is nil.")
    }
    
    
    // MARK: - Read Favorite
    
    func getFavoriteMemoEntities() -> [MemoEntity] {
        
        guard let orderCriterion = UserDefaults.standard.string(forKey: UserDefaultsKeys.orderCriterion.rawValue) else { fatalError() }
        guard let isAscending = UserDefaults.standard.value(forKey: UserDefaultsKeys.isOrderAscending.rawValue) as? Bool else { fatalError() }
        
        
        var memoEntityList: [MemoEntity] = []
        
//        if let context = self.context {
        guard let context = self.appDelegate?.persistentContainer.viewContext else { fatalError() }
            let request = NSFetchRequest<NSManagedObject>(entityName: self.entityName)
//            let dataOrder = NSSortDescriptor(key: criterion.rawValue, ascending: ascending)
            let dataOrder = NSSortDescriptor(key: orderCriterion, ascending: isAscending)
            request.sortDescriptors = [dataOrder]
            request.predicate = NSPredicate(format: "isFavorite == true && isInTrash == false")
            
            do {
                if let fetchedMemoTextList = try context.fetch(request) as? [MemoEntity] {
                    memoEntityList = fetchedMemoTextList
                }
            } catch {
                print("fetch request failed")
            }
//        }
        return memoEntityList
    }
    
    // MARK: - Delete(Soft)
    
    
    func trashMemo(_ memoEntity: MemoEntity) {
        memoEntity.isFavorite = false
//        memoEntity.categories = NSSet()
        memoEntity.isInTrash = true
        memoEntity.deletedDate = Date()
        appDelegate?.saveContext()
        
        memoEntity.categories?.forEach({ element in
            guard let category = element as? CategoryEntity else { fatalError() }
            memoEntity.removeFromCategories(category)
        })
    }
    
    // MARK: - Restoring from Trash
    
    func restoreMemo(_ memoEntity: MemoEntity) {
        memoEntity.isInTrash = false
        memoEntity.deletedDate = nil
        appDelegate?.saveContext()
    }
    
    
    // MARK: - ⚠️ Delete(Hard)
    
    /// MemoEntity를 코어데이터에서 삭제하는 메서드
    /// - Parameter memoEntity: 삭제할 memoEntity
    ///
    /// 매개변수로 들어온 memoEntity와 그 메모에 속한 이미지들 및 imageEntity들까지 모두 삭제한다.
    func deleteMemoEntity(memoEntity: MemoEntity) {
        
        guard let context = self.appDelegate?.persistentContainer.viewContext else { fatalError() }
        guard let categories = memoEntity.categories else { return }
        guard let images = memoEntity.images as? Set<ImageEntity> else { return }
        memoEntity.removeFromCategories(categories)
        
        // 임시 저장된 이미지 삭제 (이미지 먼저 삭제 후 이미지들을 담는 디렉토리 삭제)
        images.forEach { [weak self] imageEntity in
            guard let self else { return }
            self.imageEntityManager.deleteImageEntity(imageEntity: imageEntity)
        }
        
        //memoEntity의 이미지들을 담는 디렉토리 삭제
        if #available(iOS 16, *) {
            let documentURL = fileManager.urls(
                for: FileManager.SearchPathDirectory.documentDirectory,
                in: FileManager.SearchPathDomainMask.userDomainMask)[0]
            let memoDirectoryURL = documentURL.appending(path: memoEntity.memoID.uuidString, directoryHint: URL.DirectoryHint.inferFromPath)
            
            do { try fileManager.removeItem(at: memoDirectoryURL) }
            catch { print(error.localizedDescription) }
            print("\(memoEntity.memoTitle) 디렉토리 삭제함.")
            
        } else {
            let documentURL = fileManager.urls(
                for: FileManager.SearchPathDirectory.documentDirectory,
                in: FileManager.SearchPathDomainMask.userDomainMask)[0]
            let memoDirectoryURL = documentURL.appendingPathComponent(memoEntity.memoID.uuidString)
            
            do { try fileManager.removeItem(at: memoDirectoryURL) }
            catch { print(error.localizedDescription) }
            print("\(memoEntity.memoTitle) 디렉토리 삭제함.")
            
        }
        
        
        context.delete(memoEntity)
        appDelegate?.saveContext()
        
        print(" memoEntity \"\(memoEntity.memoTitle)\" 삭제함")
        
    }
    
    // MARK: - Replace Categories
    
    func replaceCategories(of memoEntity: MemoEntity, with newCategorySet: Set<CategoryEntity>) {
        
        guard let categories = memoEntity.categories else {
            print("memo has no cateogories")
            return
        }
        let newNSSet = newCategorySet as NSSet
        memoEntity.removeFromCategories(categories)
        memoEntity.addToCategories(newNSSet)
        
//        newNSSet.forEach { categoryEntity in
//            guard let categoryEntity = categoryEntity as? CategoryEntity else { return }
//            categoryEntity.modificationDate = Date()
//        }
        
    }
    
    
    
    
//    //[Update1] fetch 메서드를 사용해서 원하는 데이터를 얻어온 다음, 여기에 새로운 값을 할당해 줌으로써 수정 가능
//    //targetMemoEntityToUpdate가 wrtie만 되고 read가 되지는 않았다고 노란색 경고창이 뜰 거임.
//    //이 함수는 쓰기만 하고 읽는 기능은 없으니 무시하면 됨.
//    func updateMemoEntity(newMemoEntity: MemoEntity) {
//        
//        guard let context else { return }
//        let request = NSFetchRequest<NSManagedObject>(entityName: self.entityName)
//        request.predicate = NSPredicate(format: "creationDate = %@", newMemoEntity.creationDate as CVarArg)
//        
//        do {
//            guard let fetchedMemoEntityList = try context.fetch(request) as? [MemoEntity] else { return }
//            //targetMemoEntityToUpdate가 wrtie만 되고 read가 되지는 않았다고 노란색 경고창이 뜰 거임.
//            //이 함수는 쓰기만 하고 읽는 기능은 없으니 무시하면 됨.
//            //creationDate를 기준으로 가져온 [MemoEntity] 타입의 배열의 요소는 하나뿐임. (생성날짜는 고유한 값)
//            guard var memoEntityToUpdate = fetchedMemoEntityList.first else { return }
//            memoEntityToUpdate = newMemoEntity
//            appDelegate?.saveContext()
//        } catch {
//            print("update failed")
//        }
//    }
    
    // MARK: - Toggle Favorite
    
    func togglesFavorite(in memoEntity: MemoEntity) {
        memoEntity.isFavorite.toggle()
        appDelegate?.saveContext()
    }
    
    // MARK: - Set Favorite
    
    func setFavorite(of memoEntity: MemoEntity, to value: Bool) {
        memoEntity.isFavorite = value
        appDelegate?.saveContext()
    }
    
}

