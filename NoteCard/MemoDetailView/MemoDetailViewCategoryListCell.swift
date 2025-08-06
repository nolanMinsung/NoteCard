//
//  MemoDetailViewSelectCategoryCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/18.
//

import UIKit

final class MemoDetailViewCategoryListCell: UICollectionViewCell {
    
    static var cellID: String {
        return String(describing: self)
    }
    
    private let deselectedTextColor: UIColor = .init(dynamicProvider: {
        return $0.userInterfaceStyle == .dark ? .lightGray : .darkGray
    })
    
    var categoryEntity: CategoryEntity!
    
    let selectionAnimator = UIViewPropertyAnimator(duration: 0.2, curve: UIView.AnimationCurve.easeOut)
    let deselectionAnimator = UIViewPropertyAnimator(duration: 0.2, curve: UIView.AnimationCurve.easeOut)
    
    override var isSelected: Bool {
        didSet {
            
            switch isSelected {
            case true:
                self.deselectionAnimator.stopAnimation(true)
                self.selectionAnimator.addAnimations {
                    
                    self.label.textColor = .label
                    self.label.alpha = 1.0
                    self.contentView.backgroundColor = .detailViewCategoryCellSelectedBackground
                    self.contentView.layer.borderWidth = 1
                }
                self.selectionAnimator.startAnimation()
                
            case false:
                self.selectionAnimator.stopAnimation(true)
                self.deselectionAnimator.addAnimations { [weak self] in
                    guard let self else { return }
                    self.label.textColor = self.deselectedTextColor
                    self.label.alpha = 0.5
                    self.contentView.backgroundColor = .detailViewCategoryCellDeselectedBackground
                    self.contentView.layer.borderWidth = 0
                }
                self.deselectionAnimator.startAnimation()
            }
        }
    }
    
    
    let label: UILabel = {
        
        let detailViewCategoryCellLabelColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.lightGray
            } else {
                return UIColor.darkGray
            }
        }
        
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.numberOfLines = 1
        label.textColor = detailViewCategoryCellLabelColor
        label.alpha = 0.5
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        configureHierarchy()
        setupConstraints()
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.sizeToFit()
        self.contentView.layer.borderColor = UIColor.currentTheme.cgColor
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
//        if self.isSelected {
//            self.contentView.backgroundColor = .systemGray5
//            self.label.alpha = 1
//        }
        
        self.label.textColor = self.deselectedTextColor
        self.label.alpha = 0.5
        self.contentView.layer.borderWidth = 0
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setupUI() {
        self.contentView.clipsToBounds = true
        self.contentView.layer.cornerRadius = 15
        self.contentView.layer.cornerCurve = .continuous
        self.contentView.backgroundColor = .detailViewCategoryCellDeselectedBackground
        self.contentView.layer.borderWidth = 0
        self.contentView.layer.borderColor = UIColor.currentTheme.cgColor
    }
    
    
    private func configureHierarchy() {
        self.contentView.addSubview(self.label)
    }
    
    
    private func setupConstraints() {
//        self.label.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor, constant: 0).isActive = true
//        self.label.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 0).isActive = true
        
        self.label.widthAnchor.constraint(lessThanOrEqualToConstant: 220).isActive = true
        
        self.label.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 5).isActive = true
        self.label.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 13).isActive = true
        self.label.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -13).isActive = true
        self.label.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -5).isActive = true
    }
    
    func configureCell(with categoryEntity: CategoryEntity) {
        self.categoryEntity = categoryEntity
        self.label.text = categoryEntity.name
        self.layoutSubviews()
    }
}
