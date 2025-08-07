//
//  TableViewCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/12/27.
//

import UIKit

final class DateFormatSettingTableViewCell: UITableViewCell {
    
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
    
    let checkMarkImageView: UIImageView = {
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        let image = UIImage(systemName: "checkmark", withConfiguration: imageConfiguration)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .currentTheme
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override var isSelected: Bool {
        didSet {
            switch isSelected {
            case true:
                self.checkMarkImageView.isHidden = false
            case false:
                self.checkMarkImageView.isHidden = true
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureHierarchy()
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private func configureHierarchy() {
        self.contentView.addSubview(self.label)
        self.contentView.addSubview(self.checkMarkImageView)
    }
    
    private func setupUI() {
        self.backgroundColor = .secondarySystemGroupedBackground
        self.selectionStyle = .none
    }
    
    private func setupConstraints() {
        let contentViewHeightConstraint = self.contentView.heightAnchor.constraint(equalToConstant: 44)
        contentViewHeightConstraint.priority = UILayoutPriority(751)
        contentViewHeightConstraint.isActive = true
        
        self.label.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 0).isActive = true
        self.label.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 15).isActive = true
        
        self.checkMarkImageView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 0).isActive = true
        self.checkMarkImageView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -20).isActive = true
    }
    
    override func prepareForReuse() {
        self.isSelected = false
        self.checkMarkImageView.isHidden = true
    }
    
}
