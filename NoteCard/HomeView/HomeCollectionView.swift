//
//  HomeCollectionView.swift
//  NoteCard
//
//  Created by 김민성 on 4/6/25.
//

import UIKit

final class HomeCollectionView: UICollectionView {
    
    /// 홈 컬렉션뷰에서 category Section의 레이아웃
    private static var categoryLayoutSection: NSCollectionLayoutSection {
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
    private static var cardLayoutSection: NSCollectionLayoutSection {
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
    
    init(
            favoriteSectionHandler: @escaping NSCollectionLayoutSectionVisibleItemsInvalidationHandler,
            allSectionHandler: @escaping NSCollectionLayoutSectionVisibleItemsInvalidationHandler,
        ) {
            let layout = UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, env in
                switch sectionIndex {
                case 0:
                    return Self.categoryLayoutSection
                case 1:
                    let favoriteSection = Self.cardLayoutSection
                    favoriteSection.visibleItemsInvalidationHandler = favoriteSectionHandler
                    return favoriteSection
                default:
                    let allSection = Self.cardLayoutSection
                    allSection.visibleItemsInvalidationHandler = allSectionHandler
                    return allSection
                }
            })
            super.init(frame: .zero, collectionViewLayout: layout)
        }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
