//
//  MemoDetailViewSelectedImageCollectionView.swift
//  CardMemo
//
//  Created by 김민성 on 2024/01/09.
//

import UIKit

class MemoDetailViewSelectedImageCollectionView: UICollectionView {
    
    init() {
        let itemWidth = CGSizeConstant.detailViewThumbnailSize.width
        let itemHeight = CGSizeConstant.detailViewThumbnailSize.height
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(itemWidth), heightDimension: .absolute(itemHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal
        let compositionalLayout = UICollectionViewCompositionalLayout(section: section, configuration: config)
        
        super.init(frame: .zero, collectionViewLayout: compositionalLayout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !self.clipsToBounds && !self.isHidden && self.alpha > 0.0 {
            let subviews = self.subviews.reversed()
            for member in subviews {
                let subPoint = member.convert(point, from: self)
                if let result: UIView = member.hitTest(subPoint, with:event) {
                    return result
                }
            }
        }
        return super.hitTest(point, with: event)
    }
    
}
