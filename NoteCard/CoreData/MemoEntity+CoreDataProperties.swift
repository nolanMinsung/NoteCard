//
//  MemoEntity+CoreDataProperties.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//
//

import Foundation
import CoreData


extension MemoEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MemoEntity> {
        return NSFetchRequest<MemoEntity>(entityName: "MemoEntity")
    }

    @NSManaged public var creationDate: Date
    @NSManaged public var isFavorite: Bool
    @NSManaged public var isInTrash: Bool
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var memoText: String
    @NSManaged public var memoTitle: String
    @NSManaged public var modificationDate: Date
    @NSManaged public var memoID: UUID
    @NSManaged public var deletedDate: Date?
    
    //메모와 카테고리가 서로 강한 참조하고 있으면 순환 참조 생겨서 메모리 누수 방지
    //그래서 메모의 다른 값들은 모두 강한 참조여도 categories 는 옵셔널 타입으로 할 수 밖에 없었던 이유가, 약한 참조를 해야 했기 때문.
    @NSManaged public weak var categories: NSSet?
    @NSManaged public var images: NSSet
    
    
    var memoTextShortBuffer: String {
        let paragraphsInString = self.memoText.components(separatedBy: CharacterSet.newlines)
        if self.memoText.count > 5000 && paragraphsInString.count > 4 {
            var buffer: String = ""
            for i in 0...3 {
                buffer.append(paragraphsInString[i])
                buffer.append("\n")
            }
            return buffer
        } else {
            return self.memoText
        }
    }
    
    
    
    var memoTextLongBuffer: String {
        let paragraphsInString = self.memoText.components(separatedBy: CharacterSet.newlines)
        if self.memoText.count > 5000 && paragraphsInString.count > 4 {
            var buffer: String = ""
            for i in 0...19 {
                buffer.append(paragraphsInString[i])
                buffer.append("\n")
            }
            return buffer
        } else {
            return self.memoText
        }
    }
    
    
    
    
    /// 메모를 생성한 시점. fileManager에서 이 메모 디렉토리의 이름으로 사용
//    var directoryName: String {
//        let dateFormatter = DateFormatter()
//        
////        dateFormatter.locale = Locale(identifier: "en-US")
////        dateFormatter.dateStyle = DateFormatter.Style.full
////        dateFormatter.timeStyle = DateFormatter.Style.full
//        
//        dateFormatter.dateFormat = "yyyyMMddHHmmss"
//        
////        return dateFormatter.string(from: self.creationDate)
//        return self.memoID.uuidString
//    }
    
    
    
    
    
    func getModificationDateString() -> String {
        let modificationDate = self.modificationDate
        let isTimeFormat24 = UserDefaults.standard.bool(forKey: KeysForUserDefaults.isTimeFormat24.rawValue)
        let formatterForDate = DateFormatter()
        let formatterForTime = DateFormatter()
        
        formatterForDate.dateStyle = DateFormatter.Style.medium
        if isTimeFormat24 {
            formatterForTime.dateFormat = "HH:mm"
        } else {
            formatterForTime.timeStyle = .short
        }
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        
        if calendar.isDateInToday(modificationDate) {
            return "오늘".localized() + " " + formatterForTime.string(from: modificationDate)
        } else if calendar.isDateInYesterday(self.modificationDate) {
            return "어제".localized() + " " + formatterForTime.string(from: modificationDate)
        } else {
            return formatterForDate.string(from: modificationDate)
        }
    }
    
    
    func getCreationDateInString() -> String {
        
//        let dateFormat = UserDefaults.standard.string(forKey: KeysForUserDefaults.dateFormat.rawValue)!
        let isTimeFormat24 = UserDefaults.standard.bool(forKey: KeysForUserDefaults.isTimeFormat24.rawValue)
        
        let formatterForDate = DateFormatter()
        let formatterForTime = DateFormatter()
        
        
        formatterForDate.dateStyle = DateFormatter.Style.medium
        if isTimeFormat24 {
            formatterForTime.dateFormat = "HH:mm"
        } else {
            formatterForTime.timeStyle = .short
//            if formatterForTime.locale == Locale(identifier: "ko_KR") {
//                formatterForTime.dateFormat = "a h:mm"
//            } else {
//                formatterForTime.dateFormat = "h:mm a"
//            }
        }
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        
        if calendar.isDateInToday(self.creationDate) {
            return "오늘".localized() + " " + formatterForTime.string(from: self.creationDate)
        } else if calendar.isDateInYesterday(self.creationDate) {
            return "어제".localized() + " " + formatterForTime.string(from: self.creationDate)
        } else {
            return formatterForDate.string(from: self.creationDate)
        }
        
    }
    
    
    
    
    func getDeletedDateInString() -> String {
        guard let deletedDate else { fatalError() }
        
//        let dateFormat = UserDefaults.standard.string(forKey: KeysForUserDefaults.dateFormat.rawValue)!
        let isTimeFormat24 = UserDefaults.standard.bool(forKey: KeysForUserDefaults.isTimeFormat24.rawValue)
        
        let formatterForDate = DateFormatter()
        let formatterForTime = DateFormatter()
        
        
        formatterForDate.dateStyle = DateFormatter.Style.medium
        if isTimeFormat24 {
            formatterForTime.dateFormat = "HH:mm"
        } else {
            formatterForTime.timeStyle = .short
//            if formatterForTime.locale == Locale(identifier: "ko_KR") {
//                formatterForTime.dateFormat = "a h:mm"
//            } else {
//                formatterForTime.dateFormat = "h:mm a"
//            }
        }
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        
        if calendar.isDateInToday(deletedDate) {
            return "오늘".localized() + " " + formatterForTime.string(from: deletedDate)
        } else if calendar.isDateInYesterday(deletedDate) {
            return "어제".localized() + " " + formatterForTime.string(from: deletedDate)
        } else {
            return formatterForDate.string(from: deletedDate)
        }
        
    }
    
    
    
    
}

// MARK: Generated accessors for categories
extension MemoEntity {
    
    @objc(addCategoriesObject:)
    @NSManaged public func addToCategories(_ value: CategoryEntity)
    
    @objc(removeCategoriesObject:)
    @NSManaged public func removeFromCategories(_ value: CategoryEntity)
    
    @objc(addCategories:)
    @NSManaged public func addToCategories(_ values: NSSet)
    
    @objc(removeCategories:)
    @NSManaged public func removeFromCategories(_ values: NSSet)

}

// MARK: Generated accessors for images
extension MemoEntity {

    @objc(addImagesObject:)
    @NSManaged public func addToImages(_ value: ImageEntity)

    @objc(removeImagesObject:)
    @NSManaged public func removeFromImages(_ value: ImageEntity)

    @objc(addImages:)
    @NSManaged public func addToImages(_ values: NSSet)

    @objc(removeImages:)
    @NSManaged public func removeFromImages(_ values: NSSet)

}

extension MemoEntity : Identifiable {

}
