//
//  ThemeColor.swift
//  NoteCard
//
//  Created by 김민성 on 8/6/25.
//

import UIKit
import Shared

public enum ThemeColor: String, CaseIterable {
    
    case black
    case brown
    case red
    case orange
    case yellow
    case green
    case skyBlue
    case blue
    case purple
    
    public func toUIColor() -> UIColor {
        let uiColor: UIColor
        
        switch self {
        case .black:
            uiColor = .msBlack
        case .brown:
            uiColor = .msBrown
        case .red:
            uiColor = .msRed
        case .orange:
            uiColor = .msOrange
        case .yellow:
            uiColor = .msYellow
        case .green:
            uiColor = .msGreen
        case .skyBlue:
            uiColor = .msSkyBlue
        case .blue:
            uiColor = .msBlue
        case .purple:
            uiColor = .msPurple
        }
        return uiColor
    }
    
}
