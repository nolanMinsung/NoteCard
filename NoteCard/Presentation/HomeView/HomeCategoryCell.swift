//
//  HomeCategoryCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class HomeCategoryCell: UICollectionViewCell, ViewShrinkable {
    
    override var isHighlighted: Bool {
        didSet { isHighlighted ? shrink(scale: 0.95) : restore() }
    }
    
    let labelCategoryName: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textAlignment = .center
        label.numberOfLines = 4
        label.textColor = UIColor.label
        label.backgroundColor = UIColor.clear
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
    
    func setupUI() {
        self.contentView.backgroundColor = UIColor.memoBackground
        self.contentView.addSubview(labelCategoryName)
        
        self.contentView.clipsToBounds = true
        self.contentView.layer.cornerRadius = 25
        self.contentView.layer.cornerCurve = .continuous
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.contentView.traitCollection.userInterfaceStyle == .dark {
            self.layer.shadowPath = nil
            self.layer.shadowColor = nil
            
        } else {
            let roundBezierPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 3, width: 100, height: 100), cornerRadius: 28)
            self.layer.shadowPath = roundBezierPath.cgPath
            self.layer.shadowOpacity = 0.2
            self.layer.shadowRadius = 5
            self.layer.shadowColor = UIColor.currentTheme.cgColor
        }
        
    }
    
    func setupConstraints() {
        labelCategoryName.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor, constant: 0).isActive = true
        labelCategoryName.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 0).isActive = true
        labelCategoryName.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 5).isActive = true
        labelCategoryName.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -5).isActive = true
    }
    
}
