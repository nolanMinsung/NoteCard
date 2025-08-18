//
//  TotalListCellCategoryCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/17.
//

import UIKit

class TotalListCellCategoryCell: UICollectionViewCell {
    
    static var cellID: String {
        return String(describing: self)
    }
    
    
    let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.sizeToFit()
        print(self.contentView.frame.size)
    }
    
    private func setupUI() {
        
        self.contentView.backgroundColor = UIColor.memoCategoryCellBackground
        self.contentView.clipsToBounds = true
        self.contentView.layer.cornerRadius = 14
        //self.contentView.layer.borderWidth = 1
        //self.contentView.layer.borderColor
        self.contentView.addSubview(categoryLabel)
        
    }
    
    private func setupConstraints() {
        self.categoryLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 5).isActive = true
        self.categoryLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 10).isActive = true
        self.categoryLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -10).isActive = true
        self.categoryLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -5).isActive = true
        self.categoryLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 150).isActive = true
    }
    
    
    func configure(with categogryEntity: CategoryEntity) {
        self.categoryLabel.text = categogryEntity.name
    }
    
}
