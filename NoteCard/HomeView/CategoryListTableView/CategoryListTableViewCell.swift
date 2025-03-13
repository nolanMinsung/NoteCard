//
//  CategoryListTableViewCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class CategoryListTableViewCell: UITableViewCell {
    
    static var cellID: String {
        return String(describing: self)
    }
    
    let categoryEntityManager = CategoryEntityManager.shared
    
    var categoryEntity: CategoryEntity!
    
    let categoryNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let memoCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupUI()
        setupConstraints()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.contentView.addSubview(categoryNameLabel)
        self.contentView.addSubview(memoCountLabel)
    }
    
    private func setupConstraints() {
        let heightConstraint = self.contentView.heightAnchor.constraint(equalToConstant: 44)
        heightConstraint.priority = UILayoutPriority(751)
        heightConstraint.isActive = true
        
//        self.categoryNameLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10).isActive = true
        self.categoryNameLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 20).isActive = true
        self.categoryNameLabel.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 0).isActive = true
        self.categoryNameLabel.trailingAnchor.constraint(equalTo: self.memoCountLabel.leadingAnchor, constant: -10).isActive = true
//        self.categoryNameLabel.setContentHuggingPriority(UILayoutPriority(750), for: NSLayoutConstraint.Axis.horizontal)
        
        self.memoCountLabel.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 0).isActive = true
        self.memoCountLabel.leadingAnchor.constraint(equalTo: self.categoryNameLabel.trailingAnchor, constant: 10).isActive = true
        self.memoCountLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -20).isActive = true
        self.memoCountLabel.setContentHuggingPriority(UILayoutPriority(751), for: NSLayoutConstraint.Axis.horizontal)
        self.memoCountLabel.setContentCompressionResistancePriority(UILayoutPriority(751), for: NSLayoutConstraint.Axis.horizontal)
    }
    
    func configureCell(with category: CategoryEntity) {
        self.categoryEntity = category
        self.categoryNameLabel.text = category.name
        self.memoCountLabel.text = String(self.categoryEntityManager.memoCounted(of: category))
    }
    

}

