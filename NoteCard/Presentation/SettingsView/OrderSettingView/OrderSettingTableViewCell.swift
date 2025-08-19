//
//  TableViewCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/12/27.
//

import UIKit

final class OrderSettingTableViewCell: UITableViewCell {
    
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
        self.selectionStyle = UITableViewCell.SelectionStyle.none
    }
    
    func configureCell(image: UIImage? = nil, text: String? = "", textColor: UIColor = .label, secondaryText: String? = "", accesoryType: UITableViewCell.AccessoryType = .none) {
        
        var defaultContentConfig = self.defaultContentConfiguration()
        defaultContentConfig.image = image
        defaultContentConfig.text = text
        defaultContentConfig.secondaryText = secondaryText
        defaultContentConfig.textProperties.color = textColor
        defaultContentConfig.imageProperties.tintColor = .currentTheme
        self.contentConfiguration = defaultContentConfig
        
        self.accessoryType = accesoryType
    }
    
    
    override func prepareForReuse() {
        self.isSelected = false
        self.accessoryType = UITableViewCell.AccessoryType.none
    }
    
}
