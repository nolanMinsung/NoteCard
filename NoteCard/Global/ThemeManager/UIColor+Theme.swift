//
//  UIColor+Theme.swift
//  NoteCard
//
//  Created by 김민성 on 8/5/25.
//

import UIKit

extension UIColor {
    
    static var currentTheme: UIColor {
        guard let colorName = UserDefaults.standard.string(forKey: UserDefaultsKey.themeColor.rawValue) else {
            return .msBlack
        }
        guard let themeColor = ThemeColor(rawValue: colorName) else {
            return .msBlack
        }
        return themeColor.toUIColor()
    }
    
    static let msBlack = UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .dark {
            return .init(hexCode: "000000")
        } else {
            return .init(hexCode: "FFFFFF").withAlphaComponent(0.847)
        }
    }
    
    static let msBrown = UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .dark {
            return .init(hexCode: "BF6032")
        } else {
            return .init(hexCode: "994421")
        }
    }
    
    static let msRed = UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .dark {
            return .init(hexCode: "E02300")
        } else {
            return .init(hexCode: "E00000")
        }
    }
    
    static let msOrange = UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .dark {
            return .init(hexCode: "F89010")
        } else {
            return .init(hexCode: "F86A04")
        }
    }
    
    static let msYellow = UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .dark {
            return .init(hexCode: "FFCA40")
        } else {
            return .init(hexCode: "E9A000")
        }
    }
    
    static let msGreen = UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .dark {
            return .init(hexCode: "25CF68")
        } else {
            return .init(hexCode: "059142")
        }
    }
    
    static let msSkyBlue = UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .dark {
            return .init(hexCode: "56DAFF")
        } else {
            return .init(hexCode: "4FB0DF")
        }
    }
    
    static let msBlue = UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .dark {
            return .init(hexCode: "0A84FF")
        } else {
            return .init(hexCode: "0565E3")
        }
    }
    
    static let msPurple = UIColor { traitCollection in
        if traitCollection.userInterfaceStyle == .dark {
            return .init(hexCode: "A250CA")
        } else {
            return .init(hexCode: "7921B1")
        }
    }
    
}

