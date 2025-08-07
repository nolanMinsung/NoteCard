//
//  SettingsTableViewCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/16.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {
    
    enum SettingsTableViewCellType: CaseIterable {
        case pushing
        case none
        case button
    }
    
    static var cellID: String {
        return String(describing: self)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: UITableViewCell.CellStyle.value1, reuseIdentifier: reuseIdentifier)
        setupCellStyle()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.selectionStyle = .default
    }
    
    private func setupCellStyle() {
        self.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
    }
    
    func configureCell(image: UIImage? = nil, text: String? = "", textColor: UIColor = .label, secondaryText: String? = "", accesoryType: UITableViewCell.AccessoryType = .none) {
        
        var defaultContentConfig = self.defaultContentConfiguration()
        defaultContentConfig.image = image
        defaultContentConfig.text = text
        defaultContentConfig.secondaryText = secondaryText
        defaultContentConfig.textProperties.color = textColor
        defaultContentConfig.imageProperties.tintColor = .currentTheme.withAlphaComponent(0.8)
        self.contentConfiguration = defaultContentConfig
        
        self.accessoryType = accesoryType
    }
    
}
