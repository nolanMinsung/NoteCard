//
//  CardFrameRestorable.swift
//  NoteCard
//
//  Created by 김민성 on 7/21/25.
//

import UIKit


protocol CardFrameRestorable: UIViewController {
    
    //------*Stored Property*------//
    
    var cardTransitioningDelegate: CardTransitioningDelegate? { get set }
    
    
    //------*Stored Property*------//
    
    func getFrameOfSelectedCell(indexPath: IndexPath) -> CGRect?
    
//    func makeSelectedCellInvisible(indexPath: IndexPath)
//    
//    func makeSelectedCellVisible(indexPath: IndexPath)
    
    func restore(startFrame: CGRect, indexPath: IndexPath)
    
}


protocol CellRestorable: UICollectionViewCell {
    
    var restoringCard: RestoringCard { get }
    
}


//protocol CardRestoreableView: UIView {
//    
//    var card: RestoringCard { get }
//    
//    func setCardDisappearingInitialState(
//        startFrame: CGRect,
//        currentCellFrame: CGRect,
//        cellSnapshot: UIView?,
//        viewSnapshot: UIView?,
//    )
//    
//}




//extension CardRestoreableView {
//    
//    /// restore 직전 restoring card 의 initial state 를 설정
//    /// - Parameters:
//    ///   - startFrame: restore을 시작할 frame(작아지기 전 상태)?
//    ///   - currentCellFrame: restore 하려고 하는 최종 목적지 cell의 현재 frame (present 때와 cell의 frame이 바뀌었을 수 있으므로)
//    ///   - cellSnapshot: cell Snapshot
//    ///   - viewSnapshot: restoring 되기 전 이미지 Snapshot
//    func setCardDisappearingInitialState(
//        startFrame: CGRect,
//        currentCellFrame: CGRect,
//        cellSnapshot: UIView? = nil,
//        viewSnapshot: UIView? = nil
//    ) {
//        
//        if let cellSnapshot { card.addCellSnapshot(cellSnapshot) }
//        if let viewSnapshot { card.addViewSnapshot(viewSnapshot) }
//        card.layoutSnapshots()
//        
//        
//        card.isHidden = false
//        card.clipsToBounds = true
//        
//        let centerDiffX = startFrame.center.x - currentCellFrame.center.x
//        let centerDiffY = startFrame.center.y - currentCellFrame.center.y
//        
//        let cardWidthScaleDiff = startFrame.width / currentCellFrame.width
//        let cardHeightScaleDiff = startFrame.height / currentCellFrame.height
//        
//        let scaleT = CGAffineTransform(scaleX: cardWidthScaleDiff, y: cardHeightScaleDiff)
//        let translationT = CGAffineTransform(translationX: centerDiffX, y: centerDiffY)
//        
//        /// - Important: ⚠️ 순서 매우 중요!!!‼️
//        /// concatenating을 통해 CGAffineTransform 들을 연산할 때 맨 마지막에 추가된 transform부터 역순으로 계산된다.
//        ///
//        /// 현재 상황에서 여러 transform을 엮을 때, 다음 순서를 지켜야 함.
//        /// `scaleT`는 `translationT` 다음에 와야 한다.
//        ///     `scaleT`가 먼저 적용되면 `translationT`의 움직임은 `scaleT`의 비율만큼 적용되기 때문..s
//        card.transform = scaleT//.concatenating(translationT)
//        card.frame = startFrame
//        // dismiss될 때 card snapshot은 transform으로 늘린 거니까 cornerRadius가 37처럼 보일지라도 더 작은 게 맞다
//        card.layer.cornerRadius = 37.0 / cardWidthScaleDiff
//        
//    }
//    
//}

