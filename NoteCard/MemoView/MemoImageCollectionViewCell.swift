//
//  CardImageCollectionViewCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit


/// collection view cell for image picking collection view.
class MemoImageCollectionViewCell: UICollectionViewCell {
    
    static var cellID: String {
        return String(describing: self)
    }
    
    /// an Instance of UIImageView for showing imagePickerView
    let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = UIView.ContentMode.scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = .lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.contentView.addSubview(self.imageView)
        self.contentView.clipsToBounds = true
        self.contentView.layer.cornerRadius = 13
        self.contentView.layer.cornerCurve = .continuous
    }
    
    private func setupConstraints() {
        self.imageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0).isActive = true
        self.imageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 0).isActive = true
        self.imageView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 0).isActive = true
        self.imageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 0).isActive = true
    }
    
    
}

