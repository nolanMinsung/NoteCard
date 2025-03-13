//
//  ThemeColorPickingTableViewCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/12/20.
//

import UIKit

final class DarkModeSettingTableViewCell: UITableViewCell {
    
    static var cellID: String {
        return String(describing: self)
    }
    
    let colorNames: [String] = ThemeColor.allCases.map { "\($0)" }
    var userInterfaceStyle: UIUserInterfaceStyle = UIWindow.current!.traitCollection.userInterfaceStyle
    
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
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    private func setupCellStyle() {
        self.selectionStyle = .none
    }
    
    func configureCell(userInterfaceStyle: UIUserInterfaceStyle, text: String? = "", textColor: UIColor = .label, secondaryText: String? = "", accesoryType: UITableViewCell.AccessoryType = .none) {
        
        self.userInterfaceStyle = userInterfaceStyle
        var defaultContentConfig = self.defaultContentConfiguration()
        defaultContentConfig.text = text
        defaultContentConfig.secondaryText = secondaryText
        defaultContentConfig.textProperties.color = textColor
//        defaultContentConfig.imageProperties.tintColor = .label
//        defaultContentConfig.imageProperties.tintColor = .currentTheme().withAlphaComponent(0.7)
        
        switch userInterfaceStyle {
        case .light:
            defaultContentConfig.image = UIImage(systemName: "circle")?.withTintColor(.label, 
                                                                                      renderingMode: UIImage.RenderingMode.alwaysOriginal)
            defaultContentConfig.text = "라이트 모드".localized()
        case .dark:
            defaultContentConfig.image = UIImage(systemName: "circle.fill")?.withTintColor(.black,
                                                                                      renderingMode: UIImage.RenderingMode.alwaysOriginal)
            defaultContentConfig.text = "다크 모드".localized()
        case .unspecified:
            defaultContentConfig.image = UIImage(named: "darkModeSymbol")?.withTintColor(UIColor.label,
                                                                                         renderingMode: UIImage.RenderingMode.alwaysOriginal)
            defaultContentConfig.text = "시스템 모드".localized()
            
        @unknown default:
            return
        }
        
        self.contentConfiguration = defaultContentConfig
        self.accessoryType = .none
        
    }
}
