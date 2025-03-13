////
////  MakingVCImagePickerView.swift
////  CardMemo
////
////  Created by 김민성 on 2023/11/02.
////
//
//import UIKit
//import Photos
//
//
//final class MakingVCImagePickerView: UIView {
//    
//    
//    let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
//    lazy var blurView: UIVisualEffectView = {
//        let view = UIVisualEffectView(effect: blurEffect)
//        view.alpha = 0.0
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    
//    let screenWidth: CGFloat = {
//        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return 0 }
//        let screenSize = windowScene.screen.bounds.size
//        return screenSize.width
//    }()
//    
//    
//    lazy var imagePickerCollectionView: UICollectionView = {
//
//        let numOfItemsInRow: Int = 3
//        let interItemSpace: CGFloat = 3
//        let itemWidth = (screenWidth - interItemSpace * CGFloat(numOfItemsInRow + 1)) / CGFloat(numOfItemsInRow)
//        let itemHeight = itemWidth
//        
//        let flowLayout = UICollectionViewFlowLayout()
//        flowLayout.scrollDirection = UICollectionView.ScrollDirection.vertical
//        flowLayout.itemSize = CGSize(width: itemWidth, height: itemHeight)
//        flowLayout.minimumInteritemSpacing = interItemSpace
//        flowLayout.minimumLineSpacing = interItemSpace
//        
//        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
//        collectionView.register(MakingVCImagePickerCollectionViewCell.self, forCellWithReuseIdentifier: MakingVCImagePickerCollectionViewCell.cellID)
//        collectionView.contentInset = UIEdgeInsets(
//            top: interItemSpace,
//            left: interItemSpace,
//            bottom: interItemSpace,
//            right: interItemSpace
//        )
//        collectionView.backgroundColor = .clear
//        collectionView.scrollsToTop = true
//        collectionView.allowsMultipleSelection = true
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        return collectionView
//    }()
//    
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//        setupUI()
//        setupConstraints()
//        
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    
//    
//    private func setupUI() {
//        self.backgroundColor = .white
//        self.addSubview(self.imagePickerCollectionView)
//        //blurView를 먼저 addSubView하면 collectionView에 가려질까???
//        self.addSubview(blurView)
//    }
//    
//    
//    
//    private func setupConstraints() {
//        self.imagePickerCollectionView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
//        self.imagePickerCollectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0).isActive = true
//        self.imagePickerCollectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0).isActive = true
//        self.imagePickerCollectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
//        
//        self.blurView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
//        self.blurView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0).isActive = true
//        self.blurView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0).isActive = true
//        self.blurView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
//    }
//    
//    
//    
//}
//
