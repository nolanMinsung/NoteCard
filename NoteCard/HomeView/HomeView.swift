//
//  HomeView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

final class HomeView: UIView {
    
    let homeCollectionView = HomeCollectionView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupCollectionView()
        self.setupStyle()
        self.setupViewHierarchy()
        self.setupLayoutConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCollectionView() {
        // reusable views registering
        self.homeCollectionView.register(
            HomeHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: HomeHeaderView.reuseIdentifier
        )
        
        self.homeCollectionView.register(HomeCategoryCell.self, forCellWithReuseIdentifier: HomeCategoryCell.reuseIdentifier)
        self.homeCollectionView.register(HomeCardCell.self, forCellWithReuseIdentifier: HomeCardCell.reuseIdentifier)
    }
    
    private func setupStyle() {
        let homeViewBackgroundColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .light {
                return UIColor.systemGray6
            } else {
                return UIColor.black
            }
        }
        self.backgroundColor = homeViewBackgroundColor
        self.homeCollectionView.backgroundColor = UIColor.clear
        self.homeCollectionView.translatesAutoresizingMaskIntoConstraints = false
        self.homeCollectionView.delaysContentTouches = false
    }
    
    private func setupViewHierarchy() {
        self.addSubview(homeCollectionView)
    }
    
    private func setupLayoutConstraints() {
        NSLayoutConstraint.activate([
            self.homeCollectionView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            self.homeCollectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            self.homeCollectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            self.homeCollectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0)
        ])
    }
    
}



