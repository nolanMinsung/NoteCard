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

        case SettingsFeatureAsset.themeColorBlack.color:
            defaultContentConfig.text = L10n.ThemeColor.blackWhite
        case SettingsFeatureAsset.themeColorBrown.color:
            defaultContentConfig.text = L10n.ThemeColor.brown
        case SettingsFeatureAsset.themeColorRed.color:
            defaultContentConfig.text = L10n.ThemeColor.red
        case SettingsFeatureAsset.themeColorOrange.color:
            defaultContentConfig.text = L10n.ThemeColor.orange
        case SettingsFeatureAsset.themeColorYellow.color:
            defaultContentConfig.text = L10n.ThemeColor.yellow
        case SettingsFeatureAsset.themeColorGreen.color:
            defaultContentConfig.text = L10n.ThemeColor.green
        case SettingsFeatureAsset.themeColorSkyBlue.color:
            defaultContentConfig.text = L10n.ThemeColor.skyblue
        case SettingsFeatureAsset.themeColorBlue.color:
            defaultContentConfig.text = L10n.ThemeColor.blue
        case SettingsFeatureAsset.themeColorPurple.color:
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
