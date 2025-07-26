//
//  WispableCollectionView.swift
//  NoteCard
//
//  Created by 김민성 on 7/26/25.
//

import UIKit


public final class WispableCollectionView: UICollectionView {
    
    let cardRestoringSizeAnimator = UIViewPropertyAnimator(duration: 0.7, dampingRatio: 1)
    let cardRestoringMovingAnimator = UIViewPropertyAnimator(duration: 0.6, dampingRatio: 0.8)
    
    private let restoringCard: RestoringCard
    
    private var presentedIndexPath: IndexPath? = nil
    
    var restoringIndexPath: IndexPath? = nil {
        didSet {
            guard let restoringIndexPath else { return }
            guard let cell = cellForItem(at: restoringIndexPath) else { return }
            guard let currentWindow = window else { return }
            let convertedFrame = cell.convert(cell.contentView.frame, to: currentWindow)
            restoringCard.frame = convertedFrame
            currentWindow.layoutIfNeeded()
        }
    }
    
    init(frame: CGRect, collectionViewLayout layout: CustomCompositionalLayout, restoringCard: RestoringCard) {
        self.restoringCard = restoringCard
        super.init(frame: frame, collectionViewLayout: layout)
        
        layout.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
    
    
extension WispableCollectionView {
    
    func getDistanceDiff(startFrame: CGRect, endFrame: CGRect) -> CGPoint {
        return .init(
            x: startFrame.center.x - endFrame.center.x,
            y: startFrame.center.y - endFrame.center.y
        )
    }
    
    func getScaleT(startFrame: CGRect, endFrame: CGRect) -> CGAffineTransform {
        return.init(
            scaleX: startFrame.width / endFrame.width,
            y: startFrame.height / endFrame.height
        )
    }
    
    func restore(
        startFrame: CGRect,
        viewSnapshot: UIView? = nil,
        cellSnapshot: UIView? = nil
    ) {
        print(#function)
        cardRestoringSizeAnimator.stopAnimation(true)
//        cardRestoringSizeAnimator.finishAnimation(at: .current)
        cardRestoringMovingAnimator.stopAnimation(true)
//        cardRestoringMovingAnimator.finishAnimation(at: .current)
        
        
        
        //        guard let cardTransitioningDelegate else { return }
        //        guard let restoringIndexPath = cardTransitioningDelegate.restoringIndexPath else { return }
        guard let restoringIndexPath else { fatalError() }
        print("oooo", restoringIndexPath)
        guard let targetCell = cellForItem(at: restoringIndexPath) else {
            // 돌아갈 indexPath의 cell이 존재하지 않는 경우, 뒤처리 후 바로 return (iPadOS에서 화면 크기를 줄였다든가 등..)
            // - 탭바의 transform identity로 복구(present시 배경이 약간 작아지므로)
            // - restoringCard 상태 정리
            // - 블러 지우기
            // - 선택된 셀 다시 보이도록 설정
            // - self.restoringIndexPath에 nil 할당.
            self.restoringCard.transform = .identity
            self.restoringCard.setStateAfterRestore()
//            self.homeView.blurs.removeBlur(animated: true)
            self.makeSelectedCellVisible(indexPath: restoringIndexPath)
            self.restoringIndexPath = nil
            return
        }
        
        // restoring card 초기 위치, 크기 설정
        guard let currentWindow = window else { return }
        let convertedCellFrame = targetCell.convert(targetCell.contentView.frame, to: currentWindow)
        let scaleT = getScaleT(startFrame: startFrame, endFrame: convertedCellFrame)
        let distanceDiff = getDistanceDiff(startFrame: startFrame, endFrame: convertedCellFrame)
        restoringCard.center.x += distanceDiff.x
        restoringCard.center.y += distanceDiff.y
        restoringCard.transform = scaleT
        
        // restoring card 초기 디자인 설정 - 기본
        restoringCard.blurView.effect = UIBlurEffect(style: .regular)
        restoringCard.isHidden = false
        restoringCard.alpha = 1
        restoringCard.clipsToBounds = true
        // restoring card 초기 디자인 설정 - 기본
        
        // restoring card 초기 디자인 설정 - 커스텀
        restoringCard.layer.cornerRadius = 20
        // restoring card 초기 디자인 설정 - 커스텀
        
        // restoring card snapshot 설정
        restoringCard.setupSnapshots(
            viewSnapshot: viewSnapshot,
            cellSnapshot: cellSnapshot
        )
        
        restoringCard.superview?.layoutIfNeeded()
        
        cardRestoringMovingAnimator.addAnimations { [weak self] in
            self?.restoringCard.center.x -= distanceDiff.x
            self?.restoringCard.center.y -= distanceDiff.y
            currentWindow.layoutIfNeeded()
        }
        
        cardRestoringSizeAnimator.addAnimations { [weak self] in
            self?.restoringCard.switchSnapshots()
            self?.restoringCard.transform = .identity
//            (self?.view as! HomeView).blur.removeBlur(animated: true)
            
//            self?.tabBarController?.view.transform = .identity
            currentWindow.layoutIfNeeded()
        }
        
        cardRestoringSizeAnimator.addCompletion { [weak self] stoppedPosition in
            self?.restoringCard.setStateAfterRestore()
            self?.makeSelectedCellVisible(indexPath: restoringIndexPath)
            self?.restoringIndexPath = nil
        }
        
        cardRestoringMovingAnimator.startAnimation()
        cardRestoringSizeAnimator.startAnimation()
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
    
    func layoutInvalidated() {
        print("layout invalidated!. orthogonal scrolling detected!")
        
        // restoring될 cell의 위치를 추적
        guard let restoringIndexPath else { return }
        guard let restoringCell = cellForItem(at: restoringIndexPath) else { return }
        guard let currentWindow = window else { return }
        restoringCard.frame = restoringCell.convert(
            restoringCell.contentView.frame,
            to: currentWindow
        )
        currentWindow.layoutIfNeeded()
    }
    
}
