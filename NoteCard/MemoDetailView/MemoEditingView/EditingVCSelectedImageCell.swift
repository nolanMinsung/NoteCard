//
//  EditingVCSelectedImageCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

//import UIKit
//
//class EditingVCSelectedImageCell: UICollectionViewCell {
//    
//    static var cellID: String {
//        return String(describing: self)
//    }
//    
//    let imageEntityManager = ImageEntityManager.shared
//    
//    var imageEntity: ImageEntity?
//    
//    let sampleImage: UIImage = {
//        guard let image = UIImage(systemName: "photo") else { return UIImage() }
//        image.withTintColor(.lightGray)
//        return image
//    }()
//    
//    lazy var selectedImageView: UIImageView = {
//        let view = UIImageView(image: self.sampleImage)
//        view.contentMode = UIImageView.ContentMode.scaleAspectFill
//        //view.clipsToBounds = true
//        //view.layer.cornerRadius = 10
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    let deleteImageButton: UIButton = {
//        let button = UIButton()
//        button.setImage(UIImage(systemName: "xmark.circle"), for: UIControl.State.normal)
//        button.tintColor = .darkGray
//        button.contentMode = .scaleAspectFill
//        button.backgroundColor  = .systemGray5
//        button.clipsToBounds = true
//        button.layer.cornerRadius = 15
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
//    
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//        setupButtonsAction()
//        setupUI()
//        setupConstraints()
//    }
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        if !self.clipsToBounds && !self.isHidden && self.alpha > 0.0 {
//            let subviews = self.subviews.reversed()
//            for member in subviews {
//                let subPoint = member.convert(point, from: self)
//                if let result: UIView = member.hitTest(subPoint, with:event) {
//                    return result
//                }
//            }
//        }
//        return super.hitTest(point, with: event)
//    }
//    
//    
//    
//    func configureCell(with imageEntity: ImageEntity) {
//        
//        self.imageEntity = imageEntity
//        let thumbnailImageToShow = self.imageEntityManager.getThumbnailImage(imageEntity: imageEntity)
//        self.selectedImageView.image = thumbnailImageToShow
//        
//    }
//    
//    
//    
//    private func setupButtonsAction() {
//        self.deleteImageButton.addTarget(self, action: #selector(deleteImageButtonTapped), for: UIControl.Event.touchUpInside)
//    }
//    
//    @objc private func deleteImageButtonTapped() {
//        print(#function)
//        self.imageEntity?.isTemporaryDeleted = true
//        NotificationCenter.default.post(Notification(name: Notification.Name("selectedImageDataSourceChanged")))
//    }
//    
//    private func setupUI() {
//        self.contentView.addSubview(selectedImageView)
//        self.contentView.clipsToBounds = true
//        self.contentView.layer.cornerRadius = 10
//        
//        self.addSubview(self.deleteImageButton)
//    }
//    
//    private func setupConstraints() {
//        self.selectedImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0).isActive = true
//        self.selectedImageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 0).isActive = true
//        self.selectedImageView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 0).isActive = true
//        self.selectedImageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 0).isActive = true
//        
//        self.deleteImageButton.centerXAnchor.constraint(equalTo: self.trailingAnchor, constant: -5).isActive = true
//        self.deleteImageButton.centerYAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 5).isActive = true
//        self.deleteImageButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
//        self.deleteImageButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
//    }
//    
//    
//    override func dragStateDidChange(_ dragState: UICollectionViewCell.DragState) {
//        switch dragState {
//        case .dragging:
//            return
//        case .lifting:
//            self.deleteImageButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
//            self.deleteImageButton.alpha = 0.0
//        case .none:
//            self.deleteImageButton.transform = CGAffineTransform.identity
//            self.deleteImageButton.alpha = 1.0
//        default:
//            return
//        }
//    }
//    
//}
//
