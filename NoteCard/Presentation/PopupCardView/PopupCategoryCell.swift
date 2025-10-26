//
//  PopupCategoryCell.swift
//  NoteCard
//
//  Created by 김민성 on 10/26/25.
//

import UIKit

final class PopupCategoryCell: UICollectionViewCell {
    
    private let nameLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        setupHierarchy()
        setupLayoutConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


private extension PopupCategoryCell {
    
    func setupUI() {
        contentView.backgroundColor = UIColor.memoCategoryCellBackground
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 15
        
        nameLabel.font = UIFont.systemFont(ofSize: 15)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1
    }
    
    func setupHierarchy() {
        contentView.addSubview(nameLabel)
    }
    
    func setupLayoutConstraints() {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
        ])
    }
    
}


extension PopupCategoryCell {
    
    func configure(with category: Category) {
        nameLabel.text = category.name
    }
    
}
