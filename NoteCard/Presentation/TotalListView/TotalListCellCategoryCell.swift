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
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .center
        label.numberOfLines = 1
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
    
//    override func layoutSubviews() {
//        super.layoutSubviews()
////        self.sizeToFit()
//        print(self.contentView.frame.size)
//    }
    
    private func setupUI() {
        contentView.backgroundColor = UIColor.memoCategoryCellBackground
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 14
        //contentView.layer.borderWidth = 1
        //contentView.layer.borderColor
        contentView.addSubview(categoryLabel)
    }
    
    private func setupConstraints() {
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
//        categoryLabel.setContentHuggingPriority(.required, for: .horizontal)
//        categoryLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        NSLayoutConstraint.activate([
            categoryLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            categoryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            categoryLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            categoryLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
//            categoryLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 150),
//            categoryLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
        ])
    }
    
    func configure(with categogryEntity: CategoryEntity) {
        self.categoryLabel.text = categogryEntity.name
    }
    
    func configure(with category: Category) {
        self.categoryLabel.text = category.name
    }
    
}
