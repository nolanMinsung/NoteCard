//
//  Date+.swift
//  NoteCard
//
//  Created by 김민성 on 9/9/25.
//

import Foundation

extension Date {
    
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
        
        if calendar.isDateInToday(self) {
            return "오늘".localized() + " " + formatterForTime.string(from: self)
        } else if calendar.isDateInYesterday(self) {
            return "어제".localized() + " " + formatterForTime.string(from: self)
        } else {
            return formatterForDate.string(from: self)
        }
        
    }
    
    func getModificationDateString() -> String {
        let modificationDate = self
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
            return "오늘".localized() + " " + formatterForTime.string(from: modificationDate)
        } else if calendar.isDateInYesterday(self) {
            return "어제".localized() + " " + formatterForTime.string(from: modificationDate)
        } else {
            return formatterForDate.string(from: modificationDate)
        }
    }
    
    
    
}
