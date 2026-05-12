//
//  ThemeColorPickingTableViewCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/12/20.
//

import UIKit
import Domain
import DesignSystem
import Shared

final class ThemeColorPickingTableViewCell: UITableViewCell {
    
    static var cellID: String {
        return String(describing: self)
    }
    
    let colorNames: [String] = ThemeColor.allCases.map { "\($0)" }
    
    override var isSelected: Bool {
        didSet {
            switch isSelected {
            case true:
                self.accessoryType = .checkmark
            case false:
                self.accessoryType = .none
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: UITableViewCell.CellStyle.value1, reuseIdentifier: reuseIdentifier)
        setupCellStyle()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCellStyle() {
        self.selectionStyle = .none
    }
    
    func configureCell(themeColor: UIColor, text: String? = "", textColor: UIColor = .label, secondaryText: String? = "", accesoryType: UITableViewCell.AccessoryType = .none) {
        
        var defaultContentConfig = self.defaultContentConfiguration()
        defaultContentConfig.image = UIImage(systemName: "circle.fill")?.withTintColor(themeColor, 
                                                                                       renderingMode: UIImage.RenderingMode.alwaysOriginal)
        defaultContentConfig.text = text
        defaultContentConfig.secondaryText = secondaryText
        defaultContentConfig.textProperties.color = textColor
        defaultContentConfig.imageProperties.tintColor = .currentTheme//.withAlphaComponent(0.7)
        
        switch themeColor {

        case .themeColorBlack:
            defaultContentConfig.text = L10n.ThemeColor.blackWhite
        case .themeColorBrown:
            defaultContentConfig.text = L10n.ThemeColor.brown
        case .themeColorRed:
            defaultContentConfig.text = L10n.ThemeColor.red
        case .themeColorOrange:
            defaultContentConfig.text = L10n.ThemeColor.orange
        case .themeColorYellow:
            defaultContentConfig.text = L10n.ThemeColor.yellow
        case .themeColorGreen:
            defaultContentConfig.text = L10n.ThemeColor.green
        case .themeColorSkyBlue:
            defaultContentConfig.text = L10n.ThemeColor.skyblue
        case .themeColorBlue:
            defaultContentConfig.text = L10n.ThemeColor.blue
        case .themeColorPurple:
            defaultContentConfig.text = L10n.ThemeColor.purple
        default:
            defaultContentConfig.text = L10n.ThemeColor.black
        }
        
        self.contentConfiguration = defaultContentConfig
        
        self.accessoryType = accesoryType
    }
    
    override func prepareForReuse() {
        self.isSelected = false
        self.accessoryType = UITableViewCell.AccessoryType.none
    }
    
}
