//
//  LeftAlignedFlowLayout.swift
//  CardMemo
//
//  Created by 김민성 on 2023/12/11.
//

import UIKit

class LeftAlignedFlowLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) ->  [UICollectionViewLayoutAttributes]? {
        if self.scrollDirection == .vertical {
            let attributes = super.layoutAttributesForElements(in: rect)?.map { $0.copy() as! UICollectionViewLayoutAttributes }
            var leftMargin: CGFloat = 0.0
            var maxY: CGFloat = -1.0
            
            attributes?.forEach { layoutAttribute in
                guard layoutAttribute.representedElementCategory == .cell else {
                    return
                }
                if layoutAttribute.frame.origin.y >= maxY {
                    leftMargin = 0.0
                }
                layoutAttribute.frame.origin.x = leftMargin
                leftMargin += layoutAttribute.frame.width + self.minimumInteritemSpacing
                maxY = max(layoutAttribute.frame.maxY , maxY)
            }
            return attributes
            
        } else {
//            let attributes = super.layoutAttributesForElements(in: rect)
//            attributes?.forEach({ layoutAttributes in
//                guard layoutAttributes.representedElementCategory == .cell else {
//                    return
//                }
////                layoutAttributes.frame.origin.y = 0
////                layoutAttributes.frame.origin = .zero
//            })
            return super.layoutAttributesForElements(in: rect)
        }
    }
    
    
    
    
    
}
