//
//  WispTransitioningDelegate.swift
//  NoteCard
//
//  Created by 김민성 on 7/21/25.
//

import Combine
import UIKit


final class WispTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    let cardRestoringSizeAnimator = UIViewPropertyAnimator(duration: 0.7, dampingRatio: 1)
    let cardRestoringMovingAnimator = UIViewPropertyAnimator(duration: 0.6, dampingRatio: 0.8)
    
    let presentationInteractor = UIPercentDrivenInteractiveTransition()
    
    // IndexPath 두 개로 구분하는 경우는, dismiss중에 다른 셀을 또 탭 할 수도 있기 때문.
    private(set) var presentingIndexPath: IndexPath
    var restoringIndexPath: IndexPath? = nil
    
    private var restoringCard = RestoringCard()
    private var startCellFrame: CGRect = .zero
    
    // Snapshots
    var cellSnapshot: UIView? = nil
    var viewSnapshot: UIView? = nil
    
    let actualPresenting: any WispPresentable
    
    private(set) lazy var wispableCollectionView: WispableCollectionView = {
        actualPresenting.wispableCollectionView()
    }()
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(
        presenting: any WispPresentable,
        selectedIndexPath: IndexPath,
        cellSnapshot: UIView? = nil
    ) {
        self.actualPresenting = presenting
        self.presentingIndexPath = selectedIndexPath
        super.init()
        // 시작할 때 셀 frame
        guard let selectedCell = wispableCollectionView.cellForItem(at: selectedIndexPath) else { fatalError() }
        let convertedCellFrame = selectedCell.convert(selectedCell.contentView.frame, to: nil)
        self.startCellFrame = convertedCellFrame
        self.cellSnapshot = cellSnapshot
        
//        wispableCollectionView.restoringCard = restoringCard
        wispableCollectionView.scrollDetected.sink { [weak self] in
            self?.syncRestoringCardFrameToCell()
        }.store(in: &cancellables)
            
    }
    
    deinit {
        print("transigion deinit")
        // deinit 되는 경우는 새 wisp transition이 시작될 때.
        restoringCard.removeFromSuperview()
    }
    
    // MARK: - Presentation Controller
    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        return WispPresentationController(
            presentedViewController: presented,
            presenting: presenting,
        )
    }
    
    // MARK: - Presentation Animator
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        return WispPresentationAnimator(startFrame: startCellFrame, interactor: presentationInteractor)
    }
    
    // MARK: - Presentation Animator (Interaction)
    func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        return self.presentationInteractor
    }
    
}



extension WispTransitioningDelegate {
    
    private func syncRestoringCardFrameToCell() {
        // restoring될 cell의 위치를 추적
        guard let restoringIndexPath else { return }
        guard let restoringCell = wispableCollectionView.cellForItem(at: restoringIndexPath) else { return }
        guard let currentWindow = actualPresenting.view.window else { return }
        restoringCard.frame = restoringCell.convert(
            restoringCell.contentView.frame,
            to: currentWindow
        )
        currentWindow.layoutIfNeeded()
    }
    
}


extension WispTransitioningDelegate {
    
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
        cardRestoringSizeAnimator.stopAnimation(false)
        cardRestoringSizeAnimator.finishAnimation(at: .current)
        cardRestoringMovingAnimator.stopAnimation(false)
        cardRestoringMovingAnimator.finishAnimation(at: .current)
        
        guard let restoringIndexPath else { fatalError() }
        guard let targetCell = wispableCollectionView.cellForItem(at: restoringIndexPath) else {
            // 돌아갈 indexPath의 cell이 존재하지 않는 경우, 뒤처리 후 바로 return (iPadOS에서 화면 크기를 줄였다든가 등..)
            // - 탭바의 transform identity로 복구(present시 배경이 약간 작아지므로)
            // - restoringCard 상태 정리
            // - 블러 지우기
            // - 선택된 셀 다시 보이도록 설정
            // - self.restoringIndexPath에 nil 할당.
            restoringCard.transform = .identity
            restoringCard.setStateAfterRestore()
            self.wispableCollectionView.makeSelectedCellVisible(indexPath: restoringIndexPath)
            self.restoringIndexPath = nil
            return
        }
        
        // restoring card subView로 추가
        actualPresenting.view.addSubview(restoringCard)
        actualPresenting.view.bringSubviewToFront(restoringCard)
        
        // restoring card 초기 위치, 크기 설정
        guard let currentWindow = actualPresenting.view.window else { return }
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
        
        cardRestoringSizeAnimator.addAnimations {[weak self] in
            self?.restoringCard.switchSnapshots()
            self?.restoringCard.transform = .identity
            currentWindow.layoutIfNeeded()
        }
        
        cardRestoringSizeAnimator.addCompletion { [self] stoppedPosition in
            print("completion called")
            self.restoringCard.setStateAfterRestore()
            self.wispableCollectionView.makeSelectedCellVisible(indexPath: restoringIndexPath)
            self.restoringCard.removeFromSuperview()
            self.restoringIndexPath = nil
        }
        
        cardRestoringMovingAnimator.startAnimation()
        cardRestoringSizeAnimator.startAnimation()
    }
    
}
