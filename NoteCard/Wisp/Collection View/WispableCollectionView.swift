//
//  WispableCollectionView.swift
//  NoteCard
//
//  Created by 김민성 on 7/26/25.
//

import UIKit

import Combine

public final class WispableCollectionView: UICollectionView {
    
    private(set) var scrollDetected: PassthroughSubject<Void, Never> = .init()
    
    var restoringIndexPath: IndexPath? = nil {
        didSet {
            print("restoringIndexPath에 새 값이 할당되었습니다. nil인가? \(restoringIndexPath == nil)")
            scrollDetected.send()
        }
    }
    
    init(frame: CGRect, collectionViewLayout layout: CustomCompositionalLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        layout.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension WispableCollectionView {
    
    func makeSelectedCellInvisible(indexPath: IndexPath) {
        cellForItem(at: indexPath)?.alpha = 0
    }
    
    func makeSelectedCellVisible(indexPath: IndexPath) {
        cellForItem(at: indexPath)?.alpha = 1
    }
    
}



extension WispableCollectionView: CustomCompositionalLayoutDelegate {
    
    // scrolling(including orthogonal) detecting
    func layoutInvalidated() {
        scrollDetected.send()
    }
    
}
