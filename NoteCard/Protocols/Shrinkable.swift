//
//  Shrinkable.swift
//  NoteCard
//
//  Created by 김민성 on 4/6/25.
//

import UIKit

protocol Shrinkable: UIView {
    
    var shrinkingAnimator: UIViewPropertyAnimator { get set }
    func shrink(scale: CGFloat)
    func restore()
    
}

extension Shrinkable {
    
    func shrink(scale: CGFloat) {
        shrinkingAnimator.stopAnimation(true)
        shrinkingAnimator.addAnimations {
            self.transform = .init(scaleX: scale, y: scale)
        }
        shrinkingAnimator.startAnimation()
    }
    
    func restore() {
        shrinkingAnimator.stopAnimation(true)
        shrinkingAnimator.addAnimations {
            self.transform = .identity
        }
        shrinkingAnimator.startAnimation()
    }
    
}

//extension Shrinkable where Self: UICollectionViewCell {
//    
//    func shrink(scale: CGFloat) {
//        shrinkingAnimator.stopAnimation(true)
//        shrinkingAnimator.addAnimations {
//            self.contentView.transform = .init(scaleX: scale, y: scale)
//        }
//        shrinkingAnimator.startAnimation()
//    }
//    
//    func restore() {
//        shrinkingAnimator.stopAnimation(true)
//        shrinkingAnimator.addAnimations {
//            self.contentView.transform = .identity
//        }
//        shrinkingAnimator.startAnimation()
//    }
//    
//}
