//
//  MemoEditingView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

//import UIKit
//
//final class MemoEditingView: UIView {
//    
//    let titleTextField: UITextField = {
//        let textField = UITextField()
//        textField.font = UIFont.systemFont(ofSize: 20)
//        textField.placeholder = "제목 없음"
//        textField.textAlignment = NSTextAlignment.left
//        textField.translatesAutoresizingMaskIntoConstraints = false
//        return textField
//    }()
//    
//    lazy var selectedImageCollectionView: UICollectionView = {
//        
//        let flowLayout = UICollectionViewFlowLayout()
//        flowLayout.scrollDirection = .horizontal
//        flowLayout.itemSize = CGSize(width: 100, height: 100)
//        flowLayout.minimumLineSpacing = 20
//        
//        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
//        collectionView.register(EditingVCSelectedImageCell.self, forCellWithReuseIdentifier: EditingVCSelectedImageCell.cellID)
//        collectionView.register(MemoDetailViewSelectedImageCell.self, forCellWithReuseIdentifier: MemoDetailViewSelectedImageCell.cellID)
//        collectionView.isScrollEnabled = true
//        collectionView.backgroundColor = .clear
//        collectionView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 20)
//        collectionView.showsHorizontalScrollIndicator = false
//        collectionView.clipsToBounds = false
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        return collectionView
//    }()
//    
//    let categoryListCollectionView: UICollectionView = {
//        let flowLayout = UICollectionViewFlowLayout()
//        flowLayout.scrollDirection = UICollectionView.ScrollDirection.horizontal
//        flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
//        flowLayout.minimumInteritemSpacing = 5
//        
//        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
//        collectionView.register(EditingVCCategorySelectionCell.self, forCellWithReuseIdentifier: EditingVCCategorySelectionCell.cellID)
//        collectionView.register(MemoDetailViewCategoryListCell.self, forCellWithReuseIdentifier: MemoDetailViewCategoryListCell.cellID)
//        collectionView.isScrollEnabled = true
//        collectionView.backgroundColor = .clear
//        collectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
//        collectionView.allowsMultipleSelection = true
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        return collectionView
//    }()
//    
//    let memoTextView: UITextView = {
//        let textView = UITextView()
//        textView.backgroundColor = .clear
//        textView.font = UIFont.systemFont(ofSize: 15)
//        textView.clipsToBounds = true
//        textView.scrollsToTop = false
//        textView.layer.cornerRadius = 15
//        textView.layer.borderColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
//        textView.layer.borderWidth = 2
//        textView.contentInset = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
//        //textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
//        textView.translatesAutoresizingMaskIntoConstraints = false
//        return textView
//    }()
//    
//    lazy var selectedImageCollectionViewHeightConstraint = self.selectedImageCollectionView.heightAnchor.constraint(equalToConstant: 120)
//    lazy var memoTextViewHeightConstraint = self.memoTextView.heightAnchor.constraint(equalToConstant: 300)
//    
//    let photoBarButtonItem: UIBarButtonItem = {
//        let item = UIBarButtonItem()
//        item.image = UIImage(systemName: "photo")
//        return item
//    }()
//    
//    let tagBarButtonItem: UIBarButtonItem = {
//        let item = UIBarButtonItem()
//        item.image = UIImage(systemName: "tag")
//        return item
//    }()
//    
//    let flexibleSpaceBarButtonItem: UIBarButtonItem = {
//        let item = UIBarButtonItem(systemItem: UIBarButtonItem.SystemItem.flexibleSpace)
//        return item
//    }()
//    
//    
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//        setupUI()
//        setupConstraints()
//        setupDelegates()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        //self.endEditing(true)
//        self.memoTextView.resignFirstResponder()
//    }
//    
//    private func setupUI() {
//        self.backgroundColor = .white
//        self.addSubview(self.titleTextField)
//        self.addSubview(self.selectedImageCollectionView)
//        self.addSubview(self.categoryListCollectionView)
//        self.addSubview(self.memoTextView)
//    }
//    
//    private func setupConstraints() {
//        
//        self.titleTextField.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
//        self.titleTextField.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true
//        self.titleTextField.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -20).isActive = true
//        self.titleTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
//        
//        self.selectedImageCollectionView.topAnchor.constraint(equalTo: self.titleTextField.bottomAnchor, constant: 7).isActive = true
//        self.selectedImageCollectionView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
//        self.selectedImageCollectionView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
//        self.selectedImageCollectionViewHeightConstraint.isActive = true
//        
//        self.categoryListCollectionView.topAnchor.constraint(equalTo: self.selectedImageCollectionView.bottomAnchor, constant: 7).isActive = true
//        self.categoryListCollectionView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true
//        self.categoryListCollectionView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -20).isActive = true
//        self.categoryListCollectionView.heightAnchor.constraint(equalToConstant: 40).isActive = true
//        
//        self.memoTextView.topAnchor.constraint(equalTo: self.categoryListCollectionView.bottomAnchor, constant: 7).isActive = true
//        self.memoTextView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true
//        self.memoTextView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -20).isActive = true
//        self.memoTextViewHeightConstraint.isActive = true
//    }
//    
//    private func setupDelegates() {
//        //self.memoTextView.delegate = self
//    }
//    
//    
//}
//
//
////extension MemoEditingView: UITextViewDelegate {
////    
////    
////    func textViewDidChange(_ textView: UITextView) {
////        print(#function)
////        if textView == self.memoTextView {
////            
////            let contentHeight = textView.contentSize.height
////            let yOffset = textView.contentOffset.y
////            
////            switch contentHeight {
////            case let height where height <= 150:
////                if yOffset == 0 {
////                    textView.isScrollEnabled = false
////                }
////                
////            default:
////                textView.isScrollEnabled = true
////            }
////            
////        }
////    }
////    
////    //func textViewDidChange(_ textView: UITextView) {
////    //    if textView == self.memoTextView {
////    //
////    //        let textViewContentHeight = textView.contentSize.height
////    //        let yOffset = textView.contentOffset.y
////    //
////    //
////    //
////    //        switch (textViewContentHeight, yOffset) {
////    //        case let (height, yOffset) where height <= 345 && yOffset == 0:
////    //
////    //            //self.memoTextViewHeightConstraint.constant = textView.contentSize.height
////    //            self.memoTextViewHeightConstraint.constant = 345
////    //            self.memoTextView.isScrollEnabled = true
////    //            self.layoutIfNeeded()
////    //
////    //        case let (height, yOffset) where height >= 345 && yOffset != 0:
////    //
////    //            self.memoTextViewHeightConstraint.constant = textView.contentSize.height
////    //            self.layoutIfNeeded()
////    //
////    //        case let (height, yOffset) where height > 345 && yOffset == 0:
////    //
////    //            self.memoTextViewHeightConstraint.constant = 345
////    //            self.memoTextView.isScrollEnabled = true
////    //            self.layoutIfNeeded()
////    //
////    //        case let (height, yOffset) where height <= 345 && yOffset != 0:
////    //
////    //            self.memoTextViewHeightConstraint.constant = 345
////    //            self.memoTextView.isScrollEnabled = true
////    //
////    //        default:
////    //            self.memoTextViewHeightConstraint.constant = 345
////    //            self.memoTextView.isScrollEnabled = true
////    //            self.layoutIfNeeded()
////    //        }
////    //
////    //
////    //    }
////    //}
////    
////}
//
