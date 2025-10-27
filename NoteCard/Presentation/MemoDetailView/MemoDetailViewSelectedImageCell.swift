//
//  MemoDetailViewSelectedImageCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/18.
//

import UIKit

class MemoDetailViewSelectedImageCell: UICollectionViewCell {
    
    private let selectedImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = UIImageView.ContentMode.scaleAspectFill
        return view
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        return button
    }()
    
    var onDelete: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        selectedImageView.image = nil
    }
    
    override func dragStateDidChange(_ dragState: UICollectionViewCell.DragState) {
        switch dragState {
        case .dragging:
            return
        case .lifting:
            deleteButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            deleteButton.alpha = 0.0
        case .none:
            deleteButton.transform = CGAffineTransform.identity
            deleteButton.alpha = 1.0
        @unknown default:
            return
        }
    }
    
    private func setupUI() {
        clipsToBounds = true
        layer.cornerRadius = 10
        
        contentView.addSubview(selectedImageView)
        contentView.addSubview(deleteButton)
    }
    
    private func setupConstraints() {
        selectedImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            selectedImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            selectedImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            selectedImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            selectedImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
        ])
        
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24),
        ])
    }
    
    func configureCell(with imageItem: EditableImageItem) {
        selectedImageView.image = imageItem.model.thumbnail
    }
    
    @objc private func deleteButtonTapped() {
        onDelete?()
    }
    
}
