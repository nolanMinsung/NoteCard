//
//  MemoDetailViewSelectedImageCollectionView.swift
//  CardMemo
//
//  Created by 김민성 on 2024/01/09.
//

import UIKit

class MemoDetailViewSelectedImageCollectionView: UICollectionView {
    
    init() {
        let leftAlignedFlowLayout = LeftAlignedFlowLayout()
        leftAlignedFlowLayout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        leftAlignedFlowLayout.itemSize = CGSizeConstant.detailViewThumbnailSize
        leftAlignedFlowLayout.minimumInteritemSpacing = 10
        super.init(frame: .zero, collectionViewLayout: leftAlignedFlowLayout)
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
