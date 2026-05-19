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
    
    func configureCell(themeColor: ThemeColor, text: String? = "", textColor: UIColor = .label, secondaryText: String? = "", accesoryType: UITableViewCell.AccessoryType = .none) {

        var defaultContentConfig = self.defaultContentConfiguration()
        defaultContentConfig.image = UIImage(systemName: "circle.fill")?.withTintColor(themeColor.toUIColor(),
                                                                                       renderingMode: UIImage.RenderingMode.alwaysOriginal)
        defaultContentConfig.text = text
        defaultContentConfig.secondaryText = secondaryText
        defaultContentConfig.textProperties.color = textColor
        defaultContentConfig.imageProperties.tintColor = .currentTheme

        switch themeColor {
        case .black:
            defaultContentConfig.text = L10n.ThemeColor.blackWhite
        case .brown:
            defaultContentConfig.text = L10n.ThemeColor.brown
        case .red:
            defaultContentConfig.text = L10n.ThemeColor.red
        case .orange:
            defaultContentConfig.text = L10n.ThemeColor.orange
        case .yellow:
            defaultContentConfig.text = L10n.ThemeColor.yellow
        case .green:
            defaultContentConfig.text = L10n.ThemeColor.green
        case .skyBlue:
            defaultContentConfig.text = L10n.ThemeColor.skyblue
        case .blue:
            defaultContentConfig.text = L10n.ThemeColor.blue
        case .purple:
            defaultContentConfig.text = L10n.ThemeColor.purple
        }
        
        self.contentConfiguration = defaultContentConfig
        
        self.accessoryType = accesoryType
    }
    
    override func prepareForReuse() {
        self.isSelected = false
        self.accessoryType = UITableViewCell.AccessoryType.none
    }
    
}
