//
//  UIColor+.swift
//  NoteCard
//
//  Created by 김민성 on 7/18/25.
//

import UIKit


extension UIColor {
    
    convenience init(hexCode: String, alpha: CGFloat = 1.0) {
        var hexFormatted: String = hexCode.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        
        if hexFormatted.hasPrefix("#") {
            hexFormatted = String(hexFormatted.dropFirst())
        }
        
        assert(hexFormatted.count == 6, "Invalid hex code used.")
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        
        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                  alpha: alpha)
    }
    
    
    static func currentTheme() -> UIColor {
        guard let themeColor = UserDefaults.standard.value(forKey: UserDefaultsKeys.themeColor.rawValue) as? String else {
            UserDefaults.standard.set("black", forKey: UserDefaultsKeys.themeColor.rawValue)
            return .label
        }
        
        switch themeColor {
        case "black":
            return UIColor.themeColorBlack
        case "brown":
            return UIColor.themeColorBrown
        case "red":
            return UIColor.themeColorRed
        case "orange":
            return UIColor.themeColorOrange
        case "yellow":
            return UIColor.themeColorYellow
        case "green":
            return UIColor.themeColorGreen
        case "skyBlue":
            return UIColor.themeColorSkyBlue
        case "blue":
            return UIColor.themeColorBlue
        case "purple":
            return UIColor.themeColorPurple
        default:
            return UIColor.label
        }
    }
    
    
    func toHexString() -> String {
            var r:CGFloat = 0
            var g:CGFloat = 0
            var b:CGFloat = 0
            var a:CGFloat = 0
            getRed(&r, green: &g, blue: &b, alpha: &a)
            let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
            return String(format:"#%06x", rgb)
        }
    //출처: https://kangheeseon.tistory.com/25 [개발을 잘하고 싶은 주니어?:티스토리]
    
}
