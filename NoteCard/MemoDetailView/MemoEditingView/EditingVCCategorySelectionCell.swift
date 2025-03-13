//
//  EditingVCCategorySelectionCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/14.
//

import UIKit

//class EditingVCCategorySelectionCell: UICollectionViewCell {
//    
//    
//    static var cellID: String {
//        return String(describing: self)
//    }
//    
//    
//    var categoryEntity: CategoryEntity!
//    
//    let label: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 15)
//        label.backgroundColor = .clear
//        label.textAlignment = .center
//        label.numberOfLines = 1
//        label.textColor = .black
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//        
//    }()
//    
//    
//    override var isSelected: Bool {
//        didSet {
//            
//            switch isSelected {
//            case true:
//                self.label.textColor = .systemBlue
//                self.contentView.backgroundColor = .systemGray6
//            case false:
//                self.label.textColor = .black
//                self.contentView.backgroundColor = .clear
//            }
//            
//        }
//    }
//    
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//        setupUI()
//        configureHierarchy()
//        setupConstraints()
//    }
//    
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    
//    private func setupUI() {
//        self.contentView.backgroundColor = .clear
//        self.backgroundView?.backgroundColor = .systemGray6
//        self.selectedBackgroundView?.backgroundColor = .systemRed
//        
//    }
//    
//    
//    private func configureHierarchy() {
//        self.contentView.addSubview(self.label)
//    }
//    
//    
//    private func setupConstraints() {
//        self.label.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor, constant: 0).isActive = true
//        self.label.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 0).isActive = true
//    }
//    
//    func configureCell(with categoryEntity: CategoryEntity) {
//        self.categoryEntity = categoryEntity
//        self.label.text = categoryEntity.name
//    }
//}
