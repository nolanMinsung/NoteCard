//
//  ThemeColorPickingTableViewCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/12/20.
//

import UIKit

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
            defaultContentConfig.text = "Black/White".localized()
        case .themeColorBrown:
            defaultContentConfig.text = "Brown".localized()
        case .themeColorRed:
            defaultContentConfig.text = "Red".localized()
        case .themeColorOrange:
            defaultContentConfig.text = "Orange".localized()
        case .themeColorYellow:
            defaultContentConfig.text = "Yellow".localized()
        case .themeColorGreen:
            defaultContentConfig.text = "Green".localized()
        case .themeColorSkyBlue:
            defaultContentConfig.text = "Skyblue".localized()
        case .themeColorBlue:
            defaultContentConfig.text = "Blue".localized()
        case .themeColorPurple:
            defaultContentConfig.text = "Purple".localized()
        default:
            defaultContentConfig.text = "Black".localized()
        }
        
        self.contentConfiguration = defaultContentConfig
        
        self.accessoryType = accesoryType
    }
    
    
    override func prepareForReuse() {
        self.isSelected = false
        self.accessoryType = UITableViewCell.AccessoryType.none
    }
    
}
