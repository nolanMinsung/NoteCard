//
//  UIColor+DesignSystem.swift
//  NoteCard
//
//  Created by 김민성 on 8/6/25.
//

import UIKit
import Shared

public extension UIColor {

    static let homeViewBackground = UIColor { traitCollection in
        return (traitCollection.userInterfaceStyle == .dark) ? .black : .systemGray6
    }

    /// 로그인 화면 배경. 다크모드에서 Apple 검정 버튼이 배경과 같은 색으로 묻히지 않도록
    /// 시스템 검정이 아닌 살짝 밝은 회색을 사용.
    static let loginBackground = UIColor { traitCollection in
        return (traitCollection.userInterfaceStyle == .dark) ? .secondarySystemBackground : .white
    }

}
