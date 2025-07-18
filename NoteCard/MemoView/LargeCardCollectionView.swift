//
//  MemoCompositionalCollectionView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/12/06.
//

import UIKit

class LargeCardCollectionView: UICollectionView {
    
    init() {
        let screenSize = UIScreen.current?.bounds.size
        let pagingFlowLayout = UICollectionViewFlowLayout()
        guard let screenSize else { fatalError() }
        pagingFlowLayout.scrollDirection = .horizontal
        pagingFlowLayout.estimatedItemSize = CGSize(width: screenSize.width * 0.9, height: screenSize.height * 0.5)
        pagingFlowLayout.minimumLineSpacing = 10
        pagingFlowLayout.minimumInteritemSpacing = 0
        
        super.init(frame: .zero, collectionViewLayout: pagingFlowLayout)
        
        clipsToBounds = false
        backgroundColor = .clear
        contentInset = UIEdgeInsets(top: 0, left: screenSize.width * 0.05, bottom: 0, right: screenSize.width * 0.05)
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
