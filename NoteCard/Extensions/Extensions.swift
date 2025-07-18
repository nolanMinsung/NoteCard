//
//  Extensions.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/18.
//

//swift 기본 타입이나 UIKit에서 만들어진 타입들을 확장한 코드들

import UIKit

extension UITextView {
    
    /// UITextView에 행간을 적용한 텍스트를 입력하는 메서드
    /// - Parameters:
    ///   - textString: 입력할 텍스트
    ///   - lineSpace: 텍스트의 행간. CGFloat 타입
    ///   - font: 텍스트의 폰트. UIFont 타입
    ///   - color: 텍스트의 색깔(foregroundColor). UIColo? 타입이며, nil일 경우 UIColor.black 할당)
    func setLineSpace(with textString: String, lineSpace: CGFloat, font: UIFont, textColor: UIColor? = .label) {
        
        //NSAttributedString.Key 중에는 paragraphStyle이라는 게 있는데, 이는 text 의 여러 줄에 걸쳐서 적용되는 글의 속성을 뜻하는 듯.
        //이 paragraphStyle을 잘 설정해서 글의 좌우정렬, 행간, 들여쓰기 등을 설정할 수 있다.
        //여기서는 행간을 설정해야 하므로 paragraphStyle에 행간만 설정해 주었음.
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.lineBreakStrategy = .hangulWordPriority
        mutableParagraphStyle.lineSpacing = lineSpace
        mutableParagraphStyle.paragraphSpacing = 0
        let attributes = [
            NSAttributedString.Key.paragraphStyle: mutableParagraphStyle,
            .font: font,
            .foregroundColor: textColor!
        ]
        
//        let attributedString = NSAttributedString(string: textString, attributes: attributes)
        
        self.attributedText = NSAttributedString(string: textString, attributes: attributes)
    }
}


//MARK: UIColor
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





//MARK: CGRect
extension CGRect {
    var center: CGPoint {
        get { return CGPoint(x: self.origin.x + self.width / 2, y: self.origin.y + self.height / 2) }
        set { self.origin = CGPoint(x: newValue.x - self.width / 2, y: newValue.y - self.height / 2) }
    }
}





//MARK: UIWindow
extension UIWindow {
    static var current: UIWindow? {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else {
                print("UIApplication.shared.connectedScenes의 scene이 nil이라고 합니다. ")
//                continue
                fatalError()
            }
            for window in windowScene.windows {
                if window.isKeyWindow { return window }
            }
        }
//        return nil
        fatalError()
    }
}




//MARK: UIScreen
extension UIScreen {
    static var current: UIScreen? {
        UIWindow.current?.screen
    }
}





//MARK: CALayer
extension CALayer {
    func addBorder(_ arr_edge: [UIRectEdge], color: UIColor, width: CGFloat) {
        for edge in arr_edge {
            let border = CALayer()
            switch edge {
            case UIRectEdge.top:
                border.frame = CGRect.init(x: 0, y: 0, width: frame.width, height: width)
                break
            case UIRectEdge.bottom:
                border.frame = CGRect.init(x: 0, y: frame.height - width, width: frame.width, height: width)
                break
            case UIRectEdge.left:
                border.frame = CGRect.init(x: 0, y: 0, width: width, height: frame.height)
                break
            case UIRectEdge.right:
                border.frame = CGRect.init(x: frame.width - width, y: 0, width: width, height: frame.height)
                break
            default:
                break
            }
            border.backgroundColor = color.cgColor
            self.addSublayer(border)
        }
    }
}





//MARK: String
extension String {
    
    func localized(value: String = "localized 필요", comment: String = "") -> String {
        return NSLocalizedString(self, value: "", comment: "")
    }
    
}


