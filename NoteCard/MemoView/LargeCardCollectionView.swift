//
//  MemoCompositionalCollectionView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/12/06.
//

import UIKit

import Wisp

class LargeCardCollectionView: WispableCollectionView {
    
    init() {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.9),
            heightDimension: .fractionalHeight(1.0)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = .init(top: 40, leading: 0, bottom: 40, trailing: 0)
        section.orthogonalScrollingBehavior = .groupPagingCentered
        
        super.init(frame: .zero, section: section)
        
        bounces = false
        clipsToBounds = false
        backgroundColor = .clear
        register(LargeCardCollectionViewCell.self,forCellWithReuseIdentifier: LargeCardCollectionViewCell.cellID)
        isScrollEnabled = true
        decelerationRate = .fast
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !self.clipsToBounds && !self.isHidden && self.alpha > 0.0 {
            
            let visibleCells = self.visibleCells
            
            for cell in visibleCells {
                let subPoint = cell.convert(point, from: self)
                if let result: UIView = cell.hitTest(subPoint, with:event) {
                    return result
                }
            }
        }
        return super.hitTest(point, with: event)
    }
}
