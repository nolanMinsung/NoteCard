//
//  TableViewCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/12/27.
//

import UIKit

final class TimeFormatSettingTableViewCell: UITableViewCell {
    
    static var cellID: String {
        return String(describing: self)
    }
    
    let label: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 17)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let switchInCell: UISwitch = {
        let switchInCell = UISwitch()
        switchInCell.onTintColor = .currentTheme()
        switchInCell.translatesAutoresizingMaskIntoConstraints = false
        return switchInCell
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: UITableViewCell.CellStyle.value1, reuseIdentifier: reuseIdentifier)
        setupSwitch()
        setupCellStyle()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCellStyle() {
        self.accessoryView = self.switchInCell
        self.selectionStyle = .none
    }
    
    private func setupSwitch() {
        let isTimeFormat24 = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isTimeFormat24.rawValue)
        self.switchInCell.setOn(isTimeFormat24, animated: false)
        self.switchInCell.addTarget(self, action: #selector(switchInCellToggled(_:)), for: UIControl.Event.valueChanged)
    }
    
    @objc private func switchInCellToggled(_ switchInCell: UISwitch) {
        print(#function)
        switch switchInCell.isOn {
        case true:
            UserDefaults.standard.setValue(true, forKey: UserDefaultsKeys.isTimeFormat24.rawValue)
        case false:
            UserDefaults.standard.setValue(false, forKey: UserDefaultsKeys.isTimeFormat24.rawValue)
        }
    }
    
    func configureCell(image: UIImage? = nil, text: String? = "", secondaryText: String? = "") {
        var defaultContentConfig = self.defaultContentConfiguration()
        defaultContentConfig.image = image
        defaultContentConfig.text = text
        defaultContentConfig.secondaryText = secondaryText
        self.contentConfiguration = defaultContentConfig
    }
    
}
