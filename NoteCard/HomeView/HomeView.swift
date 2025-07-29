//
//  HomeView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

import Wisp

final class HomeView: UIView {
    
    /// 홈 컬렉션뷰에서 category Section의 레이아웃
    static var categoryLayoutSection: NSCollectionLayoutSection {
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
    }
    
    /// 홈 컬렉션뷰에서 card Section의 레이아웃
    static var cardLayoutSection: NSCollectionLayoutSection {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: NSCollectionLayoutDimension.fractionalWidth(1.0),
            heightDimension: NSCollectionLayoutDimension.absolute(44)
        )
        
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: NSRectAlignment.top
        )
        
        let cardItemSize = NSCollectionLayoutSize(
            widthDimension: NSCollectionLayoutDimension.absolute(145),
            heightDimension: NSCollectionLayoutDimension.absolute(220)
        )
        
        let cardItem = NSCollectionLayoutItem(layoutSize: cardItemSize)
        
        let cardGroupSize = NSCollectionLayoutSize(
            widthDimension: NSCollectionLayoutDimension.absolute(155),
            heightDimension: NSCollectionLayoutDimension.absolute(240)
        )
        
        let cardGroup = NSCollectionLayoutGroup.horizontal(layoutSize: cardGroupSize, subitems: [cardItem])
        cardGroup.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5)
        cardGroup.interItemSpacing = NSCollectionLayoutSpacing.fixed(10)
        
        let cardSection = NSCollectionLayoutSection(group: cardGroup)
        cardSection.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
        cardSection.boundarySupplementaryItems = [sectionHeader]
        cardSection.orthogonalScrollingBehavior = UICollectionLayoutSectionOrthogonalScrollingBehavior.continuous
        
        return cardSection
    }
    
    let blur = CustomIntensityBlurView(blurStyle: .regular, intensity: 0.0)
    
    let homeCollectionView: WispableCollectionView
    
    init() {
        let sectionProvider: UICollectionViewCompositionalLayoutSectionProvider = { sectionIndex, env in
            switch sectionIndex {
            case 0: return HomeView.categoryLayoutSection
            case 1: return HomeView.cardLayoutSection
            default: return HomeView.cardLayoutSection
            }
        }
        homeCollectionView = WispableCollectionView(
            frame: .zero,
            sectionProvider: sectionProvider
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
