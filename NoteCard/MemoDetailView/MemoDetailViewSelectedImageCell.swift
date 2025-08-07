//
//  MemoDetailViewSelectedImageCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/18.
//

import UIKit

class MemoDetailViewSelectedImageCell: UICollectionViewCell {
    
    static var cellID: String {
        return String(describing: self)
    }
    
    let deleteButtonProportion: CGFloat = 0.3
    let imageEntityManager = ImageEntityManager.shared
    var imageEntity: ImageEntity?
    
    let selectedImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = UIImageView.ContentMode.scaleAspectFill
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var deleteImageButton: UIButton = {
        let button = UIButton()
        
        button.setImage(UIImage(systemName: "xmark")?.withTintColor(.systemRed, renderingMode: UIImage.RenderingMode.alwaysOriginal), for: UIControl.State.normal)
        button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
        button.contentMode = .scaleAspectFit
        button.backgroundColor  = .detailViewDeleteImageButton
        button.clipsToBounds = true
        button.layer.cornerRadius = CGSizeConstant.detailViewThumbnailSize.width * self.deleteButtonProportion / 2
        button.layer.borderWidth = 3
        button.layer.borderColor = UIColor.detailViewDeleteImageButton.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupButtonsAction()
        setupUI()
        setupConstraints()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !self.clipsToBounds && !self.isHidden && self.alpha > 0.0 {
            let subviews = self.subviews.reversed()
            for member in subviews {
                let subPoint = member.convert(point, from: self)
                if let result: UIView = member.hitTest(subPoint, with:event) {
                    return result
                }
            }
        }
        return super.hitTest(point, with: event)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let buttonTraitCollection = self.deleteImageButton.traitCollection
        buttonTraitCollection.performAsCurrent {
            self.deleteImageButton.layer.borderColor = UIColor.detailViewDeleteImageButton.cgColor
        }
        
    }
    
    func configureCell(with imageEntity: ImageEntity) {
        self.imageEntity = imageEntity
        let thumbnailImageToShow = self.imageEntityManager.getThumbnailImage(imageEntity: imageEntity)
        self.selectedImageView.image = thumbnailImageToShow
    }
    
    private func setupButtonsAction() {
        self.deleteImageButton.addTarget(self, action: #selector(deleteImageButtonTapped), for: UIControl.Event.touchUpInside)
    }
    
    @objc private func deleteImageButtonTapped() {
        print(#function)
        
        //notification을 post 함과 동시에 userInfo로 imgaeEntity를 같이 보냄.
        //notification을 observe하는 객체가 MemoEditingVC이면 해당 imageEntity를 edit할 것이고,
        //notification을 observe하는 객체가 MemoMakingVC이면 해당 imageEntity를 delete할 것이다. (상황에 맞게 분기처리)
        guard let imageEntity else { return }
        NotificationCenter.default.post(Notification(name: Notification.Name("selectedImageDeletedNotification"), object: nil, userInfo: ["imageEntity": imageEntity]))
    }
    
    private func setupUI() {
        self.contentView.addSubview(selectedImageView)
        self.contentView.clipsToBounds = true
        self.contentView.layer.cornerRadius = 10
        
        self.addSubview(self.deleteImageButton)
    }
    
    private func setupConstraints() {
        self.selectedImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0).isActive = true
        self.selectedImageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 0).isActive = true
        self.selectedImageView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 0).isActive = true
        self.selectedImageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 0).isActive = true
        
        self.deleteImageButton.centerXAnchor.constraint(equalTo: self.trailingAnchor, constant: 0).isActive = true
        self.deleteImageButton.centerYAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0).isActive = true
        self.deleteImageButton.widthAnchor.constraint(equalToConstant: CGSizeConstant.detailViewThumbnailSize.width * self.deleteButtonProportion).isActive = true
        self.deleteImageButton.heightAnchor.constraint(equalToConstant: CGSizeConstant.detailViewThumbnailSize.width * self.deleteButtonProportion).isActive = true
    }
    
    override func dragStateDidChange(_ dragState: UICollectionViewCell.DragState) {
        switch dragState {
        case .dragging:
            return
        case .lifting:
            self.deleteImageButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            self.deleteImageButton.alpha = 0.0
        case .none:
            self.deleteImageButton.transform = CGAffineTransform.identity
            self.deleteImageButton.alpha = 1.0
        default:
            return
        }
    }
    
}
