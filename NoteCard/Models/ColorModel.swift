//
//  ColorModel.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/20.
//

import UIKit


//enum ThemeColor: String, CaseIterable {
//    
//    case black = "000000"
//    case brown = "#994421"
//    case red = "#E00000"
//    case orange = "#f86a04"
//    case yellow = "#E9A000"
//    case green = "#059142"
//    case skyBlue = "#26AFFF"
//    case blue = "#0565E3"
//    case purple = "#7921B1"
//    
//}

enum ThemeColor: String, CaseIterable {
    
    case black
    case brown
    case red
    case orange
    case yellow
    case green
    case skyBlue
    case blue
    case purple
    
}




//final class ThemeColorManager {
//    
//    var themeColor: [String] = ["#ffffff", "#eb6d2f", "#004094"]
//    
//    static var shared = ThemeColorManager()
//    private init() {}
//    
//    func setThemeColor(with theme: ThemeColor) {
//        UserDefaults.standard.setValue(theme.rawValue, forKey: "themeColor")
//    }
//    
//    func currentThemeColorHex() -> String {
//        guard let themeColorHex = UserDefaults.standard.value(forKey: "themeColor") as? String else { return "#ffffff" }
//        return themeColorHex
//    }
//    
//    func themeColorHex(of themeColor: ThemeColor) -> String {
//        return themeColor.rawValue
//    }
//    
//}
