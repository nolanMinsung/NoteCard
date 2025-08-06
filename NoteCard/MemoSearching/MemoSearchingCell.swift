//
//  MemoSearchingCell.swift
//  NoteCard
//
//  Created by 김민성 on 8/6/25.
//

import UIKit

class MemoSearchingCell: UICollectionViewCell, ViewShrinkable {
    
    override var isHighlighted: Bool {
        didSet { isHighlighted ? shrink(scale: 0.97) : restore() }
    }
    
    private let titleLabel: UILabel = UILabel()
    private let memoTextLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = .memoBackground
        contentView.layer.cornerRadius = 25
        contentView.layer.cornerCurve = .continuous
        
        titleLabel.font = .systemFont(ofSize: 20, weight: .medium)
        
        memoTextLabel.font = .systemFont(ofSize: 15)
        memoTextLabel.numberOfLines = 0
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(memoTextLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14)
        ])
        
        memoTextLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            memoTextLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0),
            memoTextLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            memoTextLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            memoTextLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


extension MemoSearchingCell {
    
    func configure(title: String, memoTextBuffer: String) {
        titleLabel.text = title
        memoTextLabel.text = memoTextBuffer
    }
    
}
