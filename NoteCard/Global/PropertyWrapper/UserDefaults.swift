//
//  UserDefaults.swift
//  NoteCard
//
//  Created by 김민성 on 8/5/25.
//

import Foundation

enum UserDefaultsKey: String {
    case themeColor // themeColor는 ThemeManager를 통해서만 관리.
    case dateFormat
    case isTimeFormat24
    case locale
    case orderCriterion
    case isOrderAscending
    case darkModeTheme
}


/// 사용 예시
///
/// class GlobalSettings {
///     @UserDefault(key: .userName, defaultValue: "")
///     let userName: String
/// }
@propertyWrapper struct UserDefault<T> {
    
    let key: UserDefaultsKey
    let defaultValue: T
    
    var wrappedValue: T {
        get { return UserDefaults.standard.object(forKey: key.rawValue) as? T ?? defaultValue}
        set { UserDefaults.standard.set(newValue, forKey: key.rawValue) }
    }
    
}
