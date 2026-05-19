//
//  MemoEntity+CoreDataClass.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//
//

import Foundation
import Domain
import Shared
import CoreData

@objc(MemoEntity)
public class MemoEntity: NSManagedObject {
    
    @available(*, unavailable)
    public init() {
        fatalError()
    }
    
    @objc
    override private init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    public init(context: NSManagedObjectContext) {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "MemoEntity", in: context) else { fatalError() }
        super.init(entity: entityDescription, insertInto: context)
        
        creationDate = .now
        deletedDate = nil
        isFavorite = false
        isInTrash = false
        memoID = UUID()
        memoText = ""
        memoTitle = ""
        modificationDate = .now
        categories = []
        images = []
    }
    
}

public extension MemoEntity {
    
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
        let isTimeFormat24 = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isTimeFormat24.rawValue)
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
            return L10n.Date.today + " " + formatterForTime.string(from: modificationDate)
        } else if calendar.isDateInYesterday(self.modificationDate) {
            return L10n.Date.yesterday + " " + formatterForTime.string(from: modificationDate)
        } else {
            return formatterForDate.string(from: modificationDate)
        }
    }
    
    
    func getCreationDateInString() -> String {
        
//        let dateFormat = UserDefaults.standard.string(forKey: KeysForUserDefaults.dateFormat.rawValue)!
        let isTimeFormat24 = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isTimeFormat24.rawValue)
        
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
            return L10n.Date.today + " " + formatterForTime.string(from: self.creationDate)
        } else if calendar.isDateInYesterday(self.creationDate) {
            return L10n.Date.yesterday + " " + formatterForTime.string(from: self.creationDate)
        } else {
            return formatterForDate.string(from: self.creationDate)
        }
        
    }
    
    
    
    
    func getDeletedDateInString() -> String {
        guard let deletedDate else { fatalError() }
        
//        let dateFormat = UserDefaults.standard.string(forKey: KeysForUserDefaults.dateFormat.rawValue)!
        let isTimeFormat24 = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isTimeFormat24.rawValue)
        
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
            return L10n.Date.today + " " + formatterForTime.string(from: deletedDate)
        } else if calendar.isDateInYesterday(deletedDate) {
            return L10n.Date.yesterday + " " + formatterForTime.string(from: deletedDate)
        } else {
            return formatterForDate.string(from: deletedDate)
        }
        
    }
    
}
