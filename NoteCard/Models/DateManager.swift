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
    
}

