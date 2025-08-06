//
//  CardImageShowingView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

final class CardImageShowingView: UIView {
    
    
    let blurView: UIVisualEffectView = {
        let view = UIVisualEffectView()
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let dismissButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark"), for: UIControl.State.normal)
        button.contentMode = .scaleAspectFit
        button.tintColor = .currentTheme
        button.backgroundColor = .systemBackground
        button.clipsToBounds = true
        button.alpha = 0.1
        button.layer.cornerRadius = 30
        button.layer.masksToBounds = false
        button.layer.shadowColor = UIColor.currentTheme.cgColor
        button.layer.shadowOffset = CGSize.zero
        button.layer.shadowRadius = 7
        button.layer.shadowOpacity = 0.3
        button.layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 60, height: 60), cornerRadius: 30).cgPath
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    lazy var cardImageShowingCollectionView: UICollectionView = {
        guard let screenSize = UIScreen.current?.bounds.size else { fatalError() }
        
        let flowLayout: UICollectionViewFlowLayout = {
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = .horizontal
            flowLayout.minimumLineSpacing = screenSize.width * 0.025
            flowLayout.itemSize = CGSize(width: screenSize.width * 0.9, height: screenSize.height * 0.7)
            return flowLayout
        }()
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.register(CardImageShowingCollectionViewCell.self, forCellWithReuseIdentifier: CardImageShowingCollectionViewCell.cellID)
        collectionView.isScrollEnabled = true
        collectionView.contentInset.left = screenSize.width * 0.05
        collectionView.contentInset.right = screenSize.width * 0.05
        collectionView.horizontalScrollIndicatorInsets.left = screenSize.width * 0.05
        collectionView.horizontalScrollIndicatorInsets.right = screenSize.width * 0.05
        collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureHierarchy()
        setupUI()
        setupConstraints()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.dismissButton.layer.shadowColor = UIColor.currentTheme.cgColor
    }
    
    
    private func configureHierarchy() {
        self.addSubview(self.dismissButton)
        self.addSubview(self.cardImageShowingCollectionView)
        self.addSubview(self.blurView)
    }
    
    private func setupUI() {
        self.backgroundColor = .clear
    }
    
    
    private func setupConstraints() {
        guard let screenSize = UIScreen.current?.bounds.size else { fatalError() }
        
        self.dismissButton.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0).isActive = true
        //self.dismissButton.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 30).isActive = true
        self.dismissButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        self.dismissButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        self.dismissButton.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        
        self.cardImageShowingCollectionView.topAnchor.constraint(equalTo: self.topAnchor, constant: screenSize.height * 0.088).isActive = true
        self.cardImageShowingCollectionView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
        self.cardImageShowingCollectionView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
//        self.cardImageShowingCollectionView.bottomAnchor.constraint(equalTo: self.dismissButton.topAnchor, constant: -40).isActive = true
        self.cardImageShowingCollectionView.heightAnchor.constraint(equalToConstant: screenSize.height * 0.73).isActive = true
        
        
        self.blurView.topAnchor.constraint(equalTo: self.topAnchor, constant: screenSize.height * 0.088).isActive = true
        self.blurView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
        self.blurView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
        self.blurView.heightAnchor.constraint(equalToConstant: screenSize.height * 0.73).isActive = true
        
        
    }
    
}

