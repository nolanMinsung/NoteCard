//
//  EditingVCSelectedCategoryCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

//import UIKit
//
//class EditingVCSelectCategoryCell: UICollectionViewCell {
//    
//    static var selectedCategorySet: Set<CategoryEntity> = []
//    static var cellID: String {
//        return String(describing: self)
//    }
//    
//    static func fittingSize(availableHeight: CGFloat, labelText: String) -> CGSize {
//        
//        let cell = EditingVCSelectCategoryCell()
//        cell.nameLabel.text = labelText
//        
//        let targetSize = CGSize(width: UIView.layoutFittingCompressedSize.width, height: availableHeight)
//        return cell.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: UILayoutPriority.fittingSizeLevel, verticalFittingPriority: UILayoutPriority.required)
//    }
//    
//    
//    var category: CategoryEntity? {
//        didSet {
//            self.nameLabel.text = category?.name ?? "nil"
//        }
//    }
//    
//    
//    //override var isSelected: Bool {
//    //    didSet {
//    //        if isSelected {
//    //            self.contentView.backgroundColor = .systemRed
//    //        } else if !isSelected {
//    //            self.contentView.backgroundColor = .systemRed
//    //        }
//    //    }
//    //}
//    
//    
//    
//    
//    //lazy var nameView: UIView = {
//    //    let view = UIView()
//    //    view.layer.borderWidth = 0.5
//    //    view.addSubview(nameLabel)
//    //}()
//    
//    let nameLabel: UILabel = {
//        let label = UILabel()
//        label.text = "카테고리 네임 자리 위치"
//        label.numberOfLines = 1
//        label.textAlignment = NSTextAlignment.center
//        label.font = UIFont.systemFont(ofSize: 18)
//        //label.clipsToBounds = true
//        //label.layer.cornerRadius = 10
//        //label.backgroundColor = .systemTeal
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    
//    
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//        setupUI()
//        setupConstraints()
//    }
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    private func setupUI() {
//        self.contentView.clipsToBounds = true
//        self.contentView.layer.cornerRadius = 15.5
//        self.contentView.addSubview(nameLabel)
//        self.contentView.backgroundColor = .systemGray6
//        //self.contentView.layer.borderWidth = 2
//    }
//    
//    private func setupConstraints() {
//        //self.nameLabel.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 0).isActive = true
//        self.nameLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 5).isActive = true
//        self.nameLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 15).isActive = true
//        self.nameLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -15).isActive = true
//        self.nameLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -5).isActive = true
//        
//        //self.nameLabel.widthAnchor.constraint(equalToConstant: self.nameLabel.intrinsicContentSize.width).isActive = true
//    }
//    
//    
//    func toggle() {
//        guard let category else { return }
//        if self.contentView.backgroundColor == .systemGray6 {
//            self.contentView.backgroundColor = .systemGray4
//            Self.selectedCategorySet.insert(category)
//            print("SelectCell의 타입 속성 집합에 \(category.name) 넣음")
//        } else if self.contentView.backgroundColor == .systemGray4 {
//            self.contentView.backgroundColor = .systemGray6
//            Self.selectedCategorySet.remove(category)
//            print("SelectCell의 타입 속성 집합에 \(category.name) BAAAAM")
//        }
//    }
//    
//    
//}

