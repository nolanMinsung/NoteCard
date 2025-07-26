//
//  CardPoppinManagerDelegate.swift
//  NoteCard
//
//  Created by 김민성 on 7/26/25.
//

import UIKit


protocol CardPoppingManagerDelegate: UIViewController {
    
    var poppingManager: CardPoppingManager { get }
    
    // 새 presentation이 진행될 때마다 선택되는 indexPath들이 달라짐.
    // 바뀐 IndexPath에 따라 애니메이션도 달라져야 하므로 CardTransitioningDelegate 도 새로 갈아끼움.
    // -> 근데 그냥 CardTransitioningDelegate 인스턴스의 속성을 바꾸면 되는 것 아닌가..?
    // 우선 CardTransitioningDelegate의 생성자는 다음과 같음.
    /*
     CardTransitioningDelegate(
         presenting: self,
         collectionView: collectionView,
         selectedIndexPath: indexPath,
         cellSnapshot: selectedCell.snapshotView(afterScreenUpdates: false)
     )
     */
    var cardTransitioningDelegate: CardTransitioningDelegate? { get set }
    
    func makeSelectedCellInvisible(indexPath: IndexPath)
    func makeSelectedCellVisible(indexPath: IndexPath)
    
    func collectionView() -> UICollectionView
    func numberOfSections() -> Int
    func restoringCard() -> RestoringCard
    func layoutCollectionSection(in section: Int) -> NSCollectionLayoutSection
    func restore(startFrame: CGRect, indexPath: IndexPath)
}



extension CardPoppingManagerDelegate {
    
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
    
    func restore(startFrame: CGRect, indexPath: IndexPath) {
        
        guard let cardTransitioningDelegate else { return }
        guard let restoringIndexPath = cardTransitioningDelegate.restoringIndexPath else { return }
        self.poppingManager.restoringIndexPath = restoringIndexPath
        guard let targetCell = collectionView().cellForItem(
            at: restoringIndexPath
        ) as? HomeCardCell else {
            // 돌아갈 indexPath의 cell이 존재하지 않는 경우, 뒤처리 후 바로 return (iPadOS에서 화면 크기를 줄였다든가 등..)
            // - 탭바의 transform identity로 복구(present시 배경이 약간 작아지므로)
            // - restoringCard 상태 정리
            // - 블러 지우기
            // - 선택된 셀 다시 보이도록 설정
            // - self.restoringIndexPath에 nil 할당.
            self.restoringCard().transform = .identity
            self.restoringCard().setStateAfterRestore()
//            self.homeView.blurs.removeBlur(animated: true)
            self.makeSelectedCellVisible(indexPath: indexPath)
            self.poppingManager.restoringIndexPath = nil
            return
        }
        
        // restoring card 초기 위치, 크기 설정
        let convertedCellFrame = targetCell.convert(targetCell.contentView.frame, to: self.view)
        let scaleT = getScaleT(startFrame: startFrame, endFrame: convertedCellFrame)
        let distanceDiff = getDistanceDiff(startFrame: startFrame, endFrame: convertedCellFrame)
        restoringCard().center.x += distanceDiff.x
        restoringCard().center.y += distanceDiff.y
        restoringCard().transform = scaleT
        
        // restoring card 초기 디자인 설정 - 기본
        restoringCard().blurView.effect = UIBlurEffect(style: .regular)
        restoringCard().isHidden = false
        restoringCard().alpha = 1
        restoringCard().clipsToBounds = true
        // restoring card 초기 디자인 설정 - 기본
        
        // restoring card 초기 디자인 설정 - 커스텀
        restoringCard().layer.cornerRadius = 20
        // restoring card 초기 디자인 설정 - 커스텀
        
        // restoring card snapshot 설정
        restoringCard().setupSnapshots(
            viewSnapshot: cardTransitioningDelegate.viewSnapshot,
            cellSnapshot: cardTransitioningDelegate.cellSnapshot
        )
        
        let cardRestoringSizeAnimator = poppingManager.cardRestoringSizeAnimator
        let cardRestoringMovingAnimator = poppingManager.cardRestoringMovingAnimator
        
        
        cardRestoringMovingAnimator.addAnimations { [weak self] in
            self?.restoringCard().center.x -= distanceDiff.x
            self?.restoringCard().center.y -= distanceDiff.y
            self?.view.layoutIfNeeded()
        }
        
        cardRestoringSizeAnimator.addAnimations { [weak self] in
            self?.restoringCard().switchSnapshots()
            self?.restoringCard().transform = .identity
            (self?.view as! HomeView).blur.removeBlur(animated: true)
            
            self?.tabBarController?.view.transform = .identity
            self?.view.layoutIfNeeded()
        }
        
        cardRestoringSizeAnimator.addCompletion { [weak self] stoppedPosition in
            self?.restoringCard().setStateAfterRestore()
            self?.makeSelectedCellVisible(indexPath: indexPath)
            self?.poppingManager.restoringIndexPath = nil
        }
        
        cardRestoringMovingAnimator.startAnimation()
        cardRestoringSizeAnimator.startAnimation()
    }
    
}
