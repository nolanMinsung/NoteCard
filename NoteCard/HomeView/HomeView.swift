//
//  HomeView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

final class HomeView: UIView {
    
    private(set) lazy var homeCollectionView: UICollectionView = {
        let collectionView = HomeCollectionView()
        
        collectionView.register(
            HomeHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: HomeHeaderView.reuseIdentifier
        )
        
        collectionView.register(HomeCategoryCell.self, forCellWithReuseIdentifier: HomeCategoryCell.reuseIdentifier)
        collectionView.register(HomeCardCell.self, forCellWithReuseIdentifier: HomeCardCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        collectionView.delaysContentTouches = false
        return collectionView
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
        let homeViewBackgroundColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .light {
                return UIColor.systemGray6
            } else {
                return UIColor.black
            }
        }
        self.backgroundColor = homeViewBackgroundColor
        self.homeCollectionView.backgroundColor = UIColor.clear
        self.addSubview(homeCollectionView)
    }
    
    private func setupConstraints() {
        self.homeCollectionView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        self.homeCollectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0).isActive = true
        self.homeCollectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0).isActive = true
        self.homeCollectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
    }
    
}



