//
//  HomeView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

final class HomeView: UIView {
    
    let blur = CustomIntensityBlurView(blurStyle: .regular, intensity: 0.0)
    let restoringCard = RestoringCard()
    
    let homeCollectionView: HomeCollectionView
    
    init(
        favoriteSectionHandler: @escaping NSCollectionLayoutSectionVisibleItemsInvalidationHandler,
        allSectionHandler: @escaping NSCollectionLayoutSectionVisibleItemsInvalidationHandler,
    ) {
        self.homeCollectionView = HomeCollectionView(
            favoriteSectionHandler: favoriteSectionHandler,
            allSectionHandler: allSectionHandler
        )
        super.init(frame: .zero)
        
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
        
        self.blur.isUserInteractionEnabled = false
    }
    
    private func setupViewHierarchy() {
        self.addSubview(homeCollectionView)
        addSubview(blur)
        addSubview(restoringCard)
    }
    
    private func setupLayoutConstraints() {
        NSLayoutConstraint.activate([
            homeCollectionView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            homeCollectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            homeCollectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            homeCollectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
        ])
        
        blur.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            blur.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            blur.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            blur.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
        ])
    }
    
}
