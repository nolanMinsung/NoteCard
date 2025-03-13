////
////  EditingVCImagePickerCollectionViewCell.swift
////  CardMemo
////
////  Created by 김민성 on 2023/11/02.
////
//
//import UIKit
//
//class EditingVCImagePickerCollectionViewCell: UICollectionViewCell {
//    
//    static var cellID: String {
//        return String(describing: self)
//    }
//    
//    
//    let imageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.image = UIImage(systemName: "photo")
//        imageView.backgroundColor = .systemGray6
//        imageView.contentMode = UIImageView.ContentMode.scaleAspectFill
//        imageView.clipsToBounds = true
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        return imageView
//    }()
//    
//    let viewForTouchDetection: UIView = {
//        let view = UIView()
//        view.backgroundColor = .white
//        view.alpha = 0.3
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    let selectionOrderLabel: UILabel = {
//        let label = UILabel()
//        label.backgroundColor = #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
//        label.textAlignment = NSTextAlignment.center
//        label.textColor = .label
//        label.text = "선택됨"
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    lazy var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showDetailImage))
//    
//    lazy var superCollectionView = self.superview as? UICollectionView
//    var indexPath: IndexPath? {
//        guard let indexPath = self.superCollectionView?.indexPath(for: self) else { return nil }
//        return indexPath
//    }
//    
//    override var isSelected: Bool {
//        didSet{
//            if isSelected {
//                self.selectionOrderLabel.isHidden = false
//                self.layer.borderWidth = 4
//                self.layer.borderColor = #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
//            } else {
//                self.selectionOrderLabel.isHidden = true
//                self.layer.borderWidth = 0
//            }
//            
//        }
//    }
//    
//    
//    
//    
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupUI()
//        setupConstraints()
//        setupGestureRecognizer()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    
//    private func setupUI() {
//        self.contentView.addSubview(imageView)
//        self.contentView.addSubview(viewForTouchDetection)
//        self.contentView.addSubview(selectionOrderLabel)
//        self.selectionOrderLabel.isHidden = true
//    }
//    
//    
//    private func setupConstraints() {
//        self.imageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0).isActive = true
//        self.imageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 0).isActive = true
//        self.imageView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 0).isActive = true
//        self.imageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 0).isActive = true
//        
//        self.viewForTouchDetection.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 60).isActive = true
//        self.viewForTouchDetection.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 0).isActive = true
//        self.viewForTouchDetection.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 0).isActive = true
//        self.viewForTouchDetection.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 0).isActive = true
//        
//        self.selectionOrderLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 13).isActive = true
//        self.selectionOrderLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -13).isActive = true
//        
//        //self.selectionOrderLabel.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor, constant: 0).isActive = true
//        //self.selectionOrderLabel.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 0).isActive = true
//    }
//    
//    
//    private func setupGestureRecognizer() {
//        self.viewForTouchDetection.addGestureRecognizer(self.tapGestureRecognizer)
//    }
//    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        self.imageView.image = UIImage(systemName: "photo")
//    }
//    
//    @objc private func showDetailImage() {
//        NotificationCenter.default.post(name: NSNotification.Name("showDetailImageNotification"), object: self.indexPath)
//    }
//    
//}
//
