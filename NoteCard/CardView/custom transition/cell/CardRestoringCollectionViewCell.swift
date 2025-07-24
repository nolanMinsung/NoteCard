//
//  CardRestoringCollectionViewCell.swift
//  NoteCard
//
//  Created by 김민성 on 7/23/25.
//

import UIKit

class CardRestoringCollectionViewCell: UICollectionViewCell {
    
    
    private let restorePositionAnimator = UIViewPropertyAnimator(duration: 0.6, dampingRatio: 0.9)
    private let restoreScaleAnimator = UIViewPropertyAnimator(duration: 0.7, dampingRatio: 1)
    
    let restoringCard = RestoringCard()
    private(set) var isRestoring: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(restoringCard)
        restoringCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            restoringCard.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            restoringCard.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            restoringCard.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            restoringCard.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
        ])
        restoringCard.alpha = 0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        layer.zPosition = 0.0
    }
    
    
}


extension CardRestoringCollectionViewCell {
    
    func setupSnapshots(viewSnapshot: UIView?, cellSnapshot: UIView?) {
        if let viewSnapshot {
            restoringCard.addViewSnapshot(viewSnapshot)
        }
        
        if let cellSnapshot {
            restoringCard.addCellSnapshot(cellSnapshot)
        }
        
        restoringCard.layoutSnapshots()
    }
    
    func cellWillRestore(initialScaleTransform: CGAffineTransform, distanceDiff: CGPoint) {
        bringSubviewToFront(restoringCard)
        clipsToBounds = false
        restoringCard.blurView.effect = UIBlurEffect(style: .regular)
        restoringCard.isHidden = false
        restoringCard.alpha = 1
        
        restoringCard.transform = initialScaleTransform
        restoringCard.center.x += distanceDiff.x
        restoringCard.center.y += distanceDiff.y
        
        restoringCard.layoutIfNeeded()
    }
    
    func restore(initialScaleTransform: CGAffineTransform, distanceDiff: CGPoint) {
        cellWillRestore(initialScaleTransform: initialScaleTransform, distanceDiff: distanceDiff)
        makeInvisible()
        
        restorePositionAnimator.addAnimations { [weak self] in
            self?.restoringCard.switchSnapshots()
            self?.restoringCard.frame.origin = .zero
            self?.layoutIfNeeded()
        }
        
        restoreScaleAnimator.addAnimations { [weak self] in
            self?.restoringCard.transform = .identity
            self?.restoringCard.layer.cornerRadius = 20
            self?.restoringCard.clipsToBounds = true
        }
        
        restoreScaleAnimator.addCompletion { [weak self] isFinished in
            self?.restoringCard.setStateAfterRestore()
            self?.makeVisible()
        }
        
        restoreScaleAnimator.startAnimation()
        restorePositionAnimator.startAnimation()
    }
    
    
    func makeInvisible() {
        restoringCard.alpha = 1
        contentView.alpha = 0
    }
    
    func makeVisible() {
        restoringCard.alpha = 0
        contentView.alpha = 1
    }
    
    
}
