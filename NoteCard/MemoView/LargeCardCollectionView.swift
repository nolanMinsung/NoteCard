//
//  MemoCompositionalCollectionView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/12/06.
//

import UIKit

class LargeCardCollectionView: UICollectionView {
    
//    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
//        super.init(frame: frame, collectionViewLayout: layout)
//        
//    }
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
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
