//
//  UICollectionView+Wisp.swift
//  NoteCard
//
//  Created by 김민성 on 7/26/25.
//

import UIKit


extension UICollectionView {
    
    public static func makeWispable(
        frame: CGRect = .zero,
        sectionProvider: @escaping UICollectionViewCompositionalLayoutSectionProvider,
    ) -> UICollectionView {
        let customLayout = CustomCompositionalLayout(sectionProvider: sectionProvider)
        let collectionView = UICollectionView(frame: frame, collectionViewLayout: customLayout)
        return collectionView
    }
    
    // 만약 단일 섹션 레이아웃만 지원한다면:
    public static func makeWispable(
        frame: CGRect = .zero,
        section: NSCollectionLayoutSection,
    ) -> UICollectionView {
        let customLayout = CustomCompositionalLayout(section: section)
        let collectionView = UICollectionView(frame: frame, collectionViewLayout: customLayout)
        return collectionView
    }
    
}

