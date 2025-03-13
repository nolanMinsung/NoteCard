//
//  DateManager.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

final class DateManager {
    
    static let shared = DateManager()
    private init() {}
    
    enum HowOld: String {
        case today
        case yesterDay
        case theDayBeforeYesterday
        case week
        case month
        case long
    }
    
    
    //func getHowOld(date: Date) -> HowOld {
    //    let nowDate = Date()
    //    let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
    //
    //    let savedDateComponents =  calendar.dateComponents([.year, .month, .weekOfYear, .day], from: date)
    //    let nowDateCoponents = calendar.dateComponents([.year, .month, .weekOfYear, .day], from: nowDate)
    //
    //    if calendar.isDateInToday(date) {
    //        return HowOld.today
    //    } else if calendar.isDateInYesterday(date) {
    //        return HowOld.yesterDay
    //    } else {
    //
    //    }
    //}
    
    
    
}

