//
//  ImageEntityManager.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit
import CoreData

final class ImageEntityManager {
    
    let fileManager = FileManager.default
    let context = CoreDataStack.shared.persistentContainer.viewContext
    static let shared = ImageEntityManager()
    private init() {}
    
    
    weak var appDelegate = UIApplication.shared.delegate as? AppDelegate
//    lazy var context = appDeleagate?.persistentContainer.viewContext
//    weak var context: NSManagedObjectContext? {
//        guard let appDeleagate else { fatalError() }
//        return appDeleagate.persistentContainer.viewContext
//    }
    
    let entityName: String = "ImageEntity"
    
    // MARK: - Create
    
    /// create an ImagEntity with its UIImage, orderIndex and memoEntity where this ImageEntity will be embeded.
    /// - Parameters:
    ///   - image: 이미지 엔티티가 참조할 원본 이미지
    ///   - orderIndex: 이미지가 메모 내에서 갖는 순서. 0부터 시작
    ///   - memoEntity: 이미지가 포함되어야 하는 메모의 MemoEntity
    /// - Returns: ImageEntity를 생성하고, 생성된 ImageEntity? 타입인 인스턴스를 반환값으로 내놓는다.
    ///
    /// 원본 이미지를 바탕으로 썸네일 이미지를 생성하며, 썸네일 이미지의 사이즈는 300 x 300이다.
    func createImageEntity(image: UIImage, orderIndex: Int, memoEntity: MemoEntity, isTemporaryAppended: Bool = true) -> ImageEntity? {
        
        guard Int(Int64.min)...Int(Int64.max) ~= orderIndex, orderIndex >= 0 else {
            print("orderIndex is not in range of Int64")
            return nil
        }
        
        let orderIndex = Int64(orderIndex)
        
        let thumbnailImage = image.preparingThumbnail(of: CGSize(width: 400, height: 400))
        
        let imageUUID = UUID()
        let thumbnailUUID = UUID()
        
        print(imageUUID.uuidString)
        print(thumbnailUUID.uuidString)
        
        let documentURL = fileManager.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)[0]
        
        if #available(iOS 16, *) {
            let memoDirectoryURL = documentURL.appending(
                component: memoEntity.memoID.uuidString,
                directoryHint: URL.DirectoryHint.inferFromPath
            )
            let imageURLToSave = memoDirectoryURL.appending(
                component: "\(imageUUID.uuidString).jpg",
                directoryHint: URL.DirectoryHint.inferFromPath
            )
            let thumbnailURLToSave = memoDirectoryURL.appending(
                component: "\(thumbnailUUID.uuidString).jpg",
                directoryHint: URL.DirectoryHint.inferFromPath
            )
            
            guard let imageData = image.jpegData(compressionQuality: 1.0) else { return nil }
            guard let thumbnailData = thumbnailImage?.jpegData(compressionQuality: 1.0) else { return nil }
            
            do { try imageData.write(to: imageURLToSave) }
            catch { print(error.localizedDescription) }
            
            do { try thumbnailData.write(to: thumbnailURLToSave) }
            catch { print(error.localizedDescription) }
            
            print("파일매니저로 사진 저장")
            
            
        } else {
            let memoDirectoryURL = documentURL.appendingPathComponent(memoEntity.memoID.uuidString)
            let imageURLToSave = memoDirectoryURL.appendingPathComponent("\(imageUUID.uuidString).jpg")
            let thumbnailURLToSave = memoDirectoryURL.appendingPathComponent("\(thumbnailUUID.uuidString).jpg")
            
            guard let imageData = image.jpegData(compressionQuality: 1.0) else { return nil }
            guard let thumbnailData = thumbnailImage?.jpegData(compressionQuality: 1.0) else { return nil }
            
            do { try imageData.write(to: imageURLToSave) }
            catch { print(error.localizedDescription) }
            
            do { try thumbnailData.write(to: thumbnailURLToSave) }
            catch { print(error.localizedDescription) }
            
            print("파일매니저로 사진 저장")
        }
        
        
        
//        guard let context else { return nil }
        guard let entityDescription = NSEntityDescription.entity(forEntityName: self.entityName, in: context) else { return nil }
        guard let newImageEntiy = NSManagedObject(entity: entityDescription, insertInto: context) as? ImageEntity else { return nil }
        
        newImageEntiy.orderIndex = orderIndex
        newImageEntiy.temporaryOrderIndex = orderIndex
        newImageEntiy.uuid = imageUUID
        newImageEntiy.thumbnailUUID = thumbnailUUID
        newImageEntiy.memo = memoEntity
        newImageEntiy.isTemporaryDeleted = false
        newImageEntiy.isTemporaryAppended = isTemporaryAppended
        
        memoEntity.addToImages(newImageEntiy)
        
        CoreDataStack.shared.saveContext()
        print("코어데이터에 ImageEntity 저장")
        return newImageEntiy
    }
    
    // MARK: - Read
    
    /// ImageEntity의 원본 이미지를 반환하는 메서드
    /// - Parameter imageEntity: 원본 이미지에 대한 ImageEntity
    /// - Returns: UIImage? 타입으로 반환.
    func getImage(imageEntity: ImageEntity) -> UIImage? {
        let imageUUIDInString = imageEntity.uuid.uuidString
        
        
        if #available(iOS 16, *) {
            let documentURL = fileManager.urls(
                for: FileManager.SearchPathDirectory.documentDirectory,
                in: FileManager.SearchPathDomainMask.userDomainMask)[0]
            let memoDirectoryURL = documentURL.appending(path: imageEntity.memo.memoID.uuidString, directoryHint: URL.DirectoryHint.inferFromPath)
            let imageURLToRead = memoDirectoryURL.appending(path: "\(imageUUIDInString).jpg", directoryHint: URL.DirectoryHint.inferFromPath)
            
            var imageToReturn: UIImage?
            do {
                let imageData = try Data(contentsOf: imageURLToRead)
                guard let image = UIImage(data: imageData) else { return nil}
                imageToReturn = image
            } catch {
                print(error.localizedDescription)
            }
            return imageToReturn
            
            
        } else {
            let documentURL = fileManager.urls(
                for: FileManager.SearchPathDirectory.documentDirectory,
                in: FileManager.SearchPathDomainMask.userDomainMask)[0]
            let memoDirectoryURL = documentURL.appendingPathComponent(imageEntity.memo.memoID.uuidString)
            let imageURLToRead = memoDirectoryURL.appendingPathComponent("\(imageUUIDInString).jpg")
            
            var imageToReturn: UIImage?
            do {
                let imageData = try Data(contentsOf: imageURLToRead)
                guard let image = UIImage(data: imageData) else { return nil}
                imageToReturn = image
            } catch {
                print(error.localizedDescription)
            }
            return imageToReturn
            
            
        }
        
        
        
    }
    
    // MARK: - Read Thumbnail
    
    func getThumbnailImage(imageEntity: ImageEntity) -> UIImage? {
        let thumbnailUUIDInString = imageEntity.thumbnailUUID.uuidString
        
        
        if #available(iOS 16, *) {
            let documnetURL = fileManager.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)[0]
            let memoDirectoryURL = documnetURL.appending(path: imageEntity.memo.memoID.uuidString, directoryHint: URL.DirectoryHint.inferFromPath)
            let thumbnailURLToRead = memoDirectoryURL.appending(path: "\(thumbnailUUIDInString).jpg", directoryHint: URL.DirectoryHint.inferFromPath)
            
            var thumbnailToReturn: UIImage?
            do {
                let thumbnailData = try Data(contentsOf: thumbnailURLToRead)
                guard let thumbnail = UIImage(data: thumbnailData) else { return nil }
                thumbnailToReturn = thumbnail
            } catch {
                print(error.localizedDescription)
            }
            return thumbnailToReturn
            
        } else {
            let documnetURL = fileManager.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)[0]
            let memoDirectoryURL = documnetURL.appendingPathComponent(imageEntity.memo.memoID.uuidString)
            let thumbnailURLToRead = memoDirectoryURL.appendingPathComponent("\(thumbnailUUIDInString).jpg")
            
            var thumbnailToReturn: UIImage?
            do {
                let thumbnailData = try Data(contentsOf: thumbnailURLToRead)
                guard let thumbnail = UIImage(data: thumbnailData) else { return nil }
                thumbnailToReturn = thumbnail
            } catch {
                print(error.localizedDescription)
            }
            return thumbnailToReturn
            
        }
        
        
    }
    
    // MARK: - Read Entities in Memo
    
    /// 특정 메모의 ImageEntity들을 요소로 갖는 배열을 반환하는 메서드
    /// - Parameters:
    ///   - memoEntity: 이미지가 들어있는 메모
    ///   - orderIndexKind: orderIndex인지, 임시 index인지의 여부
    /// - Returns: ImageEntity를 요소로 갖는 배열
    func getImageEntities(
        from memoEntity: MemoEntity,
        inOrderOf orderIndexKind: ImageOrderIndexKind,
        isTemporaryDeleted: Bool? = nil,
        isTemporaryAppended: Bool? = nil
    ) -> [ImageEntity] {
        var arrayToReturn = [ImageEntity]()
        
        //        if let context = self.context {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ImageEntity")
        let imageOrder: NSSortDescriptor
        
        switch orderIndexKind {
        case .orderIndex:
            imageOrder = NSSortDescriptor(key: "orderIndex", ascending: true)
        case .temporaryOrderIndex:
            imageOrder = NSSortDescriptor(key: "temporaryOrderIndex", ascending: true)
        }
        
        request.sortDescriptors = [imageOrder]
        
        switch (isTemporaryDeleted, isTemporaryAppended) {
            
        case (.some(let delete), .some(let append)):
            request.predicate = NSPredicate(format: "memo == %@ && isTemporaryDeleted == %d && isTemporaryAppended == %d", memoEntity as CVarArg, delete, append)
            
        case (.none, .some(let append)):
            request.predicate = NSPredicate(format: "memo == %@ && isTemporaryAppended == %d", memoEntity as CVarArg, append)
            
        case (.some(let delete), .none):
            request.predicate = NSPredicate(format: "memo == %@ && isTemporaryDeleted == %d", memoEntity as CVarArg, delete)
            
        case (.none, .none):
            request.predicate = NSPredicate(format: "memo == %@", memoEntity as CVarArg)
            
        }
        
        
        
        
//            if let isTemporaryAppended {
//                
//                request.predicate = NSPredicate(format: "memo == %@ && isTemporaryDeleted == %@ && isTemporaryAppended == %@", memoEntity as CVarArg, isTemporaryDeleted, isTemporaryAppended)
//                
//            } else {
//                request.predicate = NSPredicate(format: "memo == %@ && isTemporaryDeleted == %@", memoEntity as CVarArg, isTemporaryDeleted)
//            }
//            switch isTemporaryDeleted {
//            case true:
//                request.predicate = NSPredicate(format: "memo == %@ && isTemporaryDeleted == true", memoEntity as CVarArg)
//            case false:
//                request.predicate = NSPredicate(format: "memo == %@ && isTemporaryDeleted == false", memoEntity as CVarArg)
//            }
        
        
        do{
            if let fetchedImageEntityArray = try context.fetch(request) as? [ImageEntity] {
                arrayToReturn = fetchedImageEntityArray
            }
        } catch {
            print(error.localizedDescription)
        }
//        }
        
        return arrayToReturn
        
    }
    
    
    // MARK: - Delete Entity
    
    //imageEntity를 삭제하는 함수. 먼저 filemanager를 통해 file 앱에 저장된 이미지를 지우고 그 다음 entity를 지우기로 한다. (만약 enttiy를 먼저 지우면, file에 저장된 이미지에 접근할 방법이 사라진다! UUID를 모르기 때문!!)
    
    /// 메모 엔티티와 그 엔티티에 해당하는 이미지 파일을 지운다.
    /// - Parameters:
    ///   - memoEntity:지울 이미지 엔티티가 속해있는 메모 엔티티
    ///   - uuid: 지울 이미지 엔티티의 uuid(고유 번호)
    ///
    /// 메모엔티티와, 해당 엔티티에 해당하는 이미지 파일을 fileManager에서 찾아서 삭제한다. 썸네일까지 모두 삭제.
    func deleteImageEntity(imageEntity: ImageEntity) {
        //1) 파일 지우기
        let uuidInString = imageEntity.uuid.uuidString
        let thumbnailUUIDInsString = imageEntity.thumbnailUUID.uuidString
        let documentURL = fileManager.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)[0]
        let memoEntity = imageEntity.memo
        
        
        
        if #available(iOS 16, *) {
            let memoDirectoryURL = documentURL.appending(path: memoEntity.memoID.uuidString, directoryHint: URL.DirectoryHint.inferFromPath)
            let imageURLToRead = memoDirectoryURL.appending(path: "\(uuidInString).jpg", directoryHint: URL.DirectoryHint.inferFromPath)
            let thumbnailURLToRead = memoDirectoryURL.appending(path: "\(thumbnailUUIDInsString).jpg", directoryHint: URL.DirectoryHint.inferFromPath)
            
            do {
                try fileManager.removeItem(at: imageURLToRead)
                try fileManager.removeItem(at: thumbnailURLToRead)
                print("이미지 파일 삭제함")
            } catch {
                print(error.localizedDescription)
            }
            
        } else {
            let memoDirectoryURL = documentURL.appendingPathComponent(memoEntity.memoID.uuidString)
            let imageURLToRead = memoDirectoryURL.appendingPathComponent("\(uuidInString).jpg")
            let thumbnailURLToRead = memoDirectoryURL.appendingPathComponent("\(thumbnailUUIDInsString).jpg")
            
            do {
                try fileManager.removeItem(at: imageURLToRead)
                try fileManager.removeItem(at: thumbnailURLToRead)
                print("이미지 파일 삭제함")
            } catch {
                print(error.localizedDescription)
            }
            
        }
        
        
        //2) 엔티티 지우기
//        guard let context else { return }
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        let predicate = NSPredicate(format: "uuid == %@", imageEntity.uuid as CVarArg)
        request.predicate = predicate
        
        do {
            guard let fetchedResultArray = try context.fetch(request) as? [ImageEntity] else { return }
            guard let fetchedResult = fetchedResultArray.first else { return }
            context.delete(fetchedResult)
            CoreDataStack.shared.saveContext()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
}
