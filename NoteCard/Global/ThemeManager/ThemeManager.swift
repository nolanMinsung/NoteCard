//
//  ThemeManager.swift
//  NoteCard
//
//  Created by 김민성 on 8/5/25.
//

import Combine
import UIKit

final class ThemeManager {
    
    let currentThemeSubject: CurrentValueSubject<UIColor, Never> = .init(UIColor.currentTheme)
    
    static let shared = ThemeManager()
    private init() {}
    
    // ThemeColor의 UserDefault 설정은 오직 ThemeManager에서만 접근 가능하도록
    private func setUserDefault(color: ThemeColor) {
        UserDefaults.standard.set(color.rawValue, forKey: UserDefaultsKey.themeColor.rawValue)
        currentThemeSubject.send(color.toUIColor())
    }
    
    func setThemeColor(_ color: ThemeColor) {
        guard currentThemeSubject.value != color.toUIColor() else { return }
        setUserDefault(color: color)
    }
    
}
