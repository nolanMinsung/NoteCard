//
//  HomeView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

final class HomeView: UIView {
    
    private let categoryLayoutSection: NSCollectionLayoutSection = {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: NSCollectionLayoutDimension.fractionalWidth(1.0),
            heightDimension: NSCollectionLayoutDimension.absolute(44)
        )
        
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: NSRectAlignment.top
        )
        
        let categoryItemSize = NSCollectionLayoutSize(
            widthDimension: NSCollectionLayoutDimension.absolute(100),
            heightDimension: NSCollectionLayoutDimension.absolute(100)
        )
        
        let categoryItem = NSCollectionLayoutItem(layoutSize: categoryItemSize)
        
        let categoryGroupSize = NSCollectionLayoutSize(
            widthDimension: NSCollectionLayoutDimension.absolute(110),
            heightDimension: NSCollectionLayoutDimension.absolute(140)
        )
        
        let categoryGroup = NSCollectionLayoutGroup.horizontal(layoutSize: categoryGroupSize, subitems: [categoryItem])
        categoryGroup.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5)
        //categoryGroup.interItemSpacing = NSCollectionLayoutSpacing.fixed(10)
        
        let categorySection = NSCollectionLayoutSection(group: categoryGroup)
        categorySection.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
        categorySection.boundarySupplementaryItems = [sectionHeader]
        categorySection.orthogonalScrollingBehavior = UICollectionLayoutSectionOrthogonalScrollingBehavior.continuous
        
        return categorySection
    }()
    
    private let cardLayoutSection: NSCollectionLayoutSection = {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: NSCollectionLayoutDimension.fractionalWidth(1.0),
            heightDimension: NSCollectionLayoutDimension.absolute(44)
        )
        
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: NSRectAlignment.top
        )
        
        let favoriteItemSize = NSCollectionLayoutSize(
            widthDimension: NSCollectionLayoutDimension.absolute(145),
            heightDimension: NSCollectionLayoutDimension.absolute(220)
        )
        
        let favoriteItem = NSCollectionLayoutItem(layoutSize: favoriteItemSize)
        
        let favoriteGroupSize = NSCollectionLayoutSize(
            widthDimension: NSCollectionLayoutDimension.absolute(155),
            heightDimension: NSCollectionLayoutDimension.absolute(240)
        )
        
        let favoriteGroup = NSCollectionLayoutGroup.horizontal(layoutSize: favoriteGroupSize, subitems: [favoriteItem])
        favoriteGroup.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5)
        favoriteGroup.interItemSpacing = NSCollectionLayoutSpacing.fixed(10)
        
        let favoriteSection = NSCollectionLayoutSection(group: favoriteGroup)
        favoriteSection.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
        favoriteSection.boundarySupplementaryItems = [sectionHeader]
        favoriteSection.orthogonalScrollingBehavior = UICollectionLayoutSectionOrthogonalScrollingBehavior.continuous
        
        return favoriteSection
    }()

    private lazy var compositionalLayout: UICollectionViewCompositionalLayout = {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, env in
            switch sectionIndex {
            case 0:
                return self?.categoryLayoutSection
            case 1:
                return self?.cardLayoutSection
            case 2:
                return self?.cardLayoutSection
            default:
                return nil
            }
        }
        return layout
    }()
    
    private(set) lazy var homeCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: compositionalLayout)
        
        collectionView.register(
            HomeHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: HomeHeaderView.reuseIdentifier
        )
        
        collectionView.register(HomeCategoryCell.self, forCellWithReuseIdentifier: HomeCategoryCell.reuseIdentifier)
        collectionView.register(HomeFavoriteCell.self, forCellWithReuseIdentifier: HomeFavoriteCell.reuseIdentifier)
        collectionView.register(HomeRecentCell.self, forCellWithReuseIdentifier: HomeRecentCell.reuseIdentifier)
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



