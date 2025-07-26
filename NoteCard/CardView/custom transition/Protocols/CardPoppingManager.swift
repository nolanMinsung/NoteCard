//
//  CardPoppingManager.swift
//  NoteCard
//
//  Created by 김민성 on 7/25/25.
//

import UIKit


import Combine

final class CardPoppingManager {
    
    let cardRestoringSizeAnimator = UIViewPropertyAnimator(duration: 0.7, dampingRatio: 1)
    let cardRestoringMovingAnimator = UIViewPropertyAnimator(duration: 0.6, dampingRatio: 0.8)
    
    var restoringIndexPath: IndexPath? = nil {
        didSet {
            guard let delegate else { return }
            guard let restoringIndexPath else { return }
            guard let cell = delegate.collectionView().cellForItem(at: restoringIndexPath) else { return }
            let convertedFrame = cell.convert(cell.contentView.frame, to: delegate.view)
            restoringCard?.frame = convertedFrame
            delegate.view.layoutIfNeeded()
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    typealias HandlerParameters = (
        Int,
        [any NSCollectionLayoutVisibleItem],
        CGPoint,
        NSCollectionLayoutEnvironment
    )
    let invalidationHandler: PassthroughSubject<HandlerParameters, Never> = .init()
    
    private var collectionView: UICollectionView? { delegate?.collectionView() }
    private var sectionCount: Int { delegate?.numberOfSections() ?? 0 }
    private var restoringCard: RestoringCard? { delegate?.restoringCard() }
    
    weak var delegate: CardPoppingManagerDelegate? = nil {
        didSet {
            guard delegate != nil else { return }
            // delegate가 할당되면
            // 1. 기존 구독 모두 해제
            cancellables = []
            // 2. 바뀐 delegate의 layoutSection에서 invalidationHandler 받아와 intercept
            interceptInvalidationHandler()
            // 3. 바뀐 delegate의 compositional layout 컬렉션뷰 스크롤 이벤트를 구독
            startSubscribingInvalidationHandler()
        }
    }
    
    private func startSubscribingInvalidationHandler() {
        invalidationHandler.sink { [weak self] (int, visibleItems, offset, environment) in
            guard let self,
                  let delegate,
                  let collectionView,
                  let restoringIndexPath,
                  let cell = collectionView.cellForItem(at: restoringIndexPath)
            else { return }
            let convertedFrame = cell.convert(cell.contentView.frame, to: delegate.view)
            restoringCard?.frame = convertedFrame
            delegate.view.layoutIfNeeded()
        }.store(in: &cancellables)
    }
    
    private func interceptInvalidationHandler() {
        let sectionCount = self.sectionCount
        for i in 0..<sectionCount {
            let sectionReference = delegate?.layoutCollectionSection(in: i)
            let visibleCellsInvalidationHandler = sectionReference?.visibleItemsInvalidationHandler
            sectionReference?.visibleItemsInvalidationHandler = { [weak self] a, b, c in
                visibleCellsInvalidationHandler?(a, b, c)
                self?.invalidationHandler.send((i, a, b, c))
            }
        }
    }
    
}

