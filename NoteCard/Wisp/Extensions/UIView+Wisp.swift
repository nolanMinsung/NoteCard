//
//  UIView+Wisp.swift
//  NoteCard
//
//  Created by 김민성 on 7/27/25.
//

import UIKit

extension UIView {
    
    // dismiss되는 시점에 cell의 snapshot을 구하기 위해 사용되는 메서드
    // (아직 사용 안함. dismiss 시에 깜박이는 문제가 있어서..)
    // present되었을 때와 dismiss되었을 때 다크모드 여부가 바뀔 경우 사용하는 것이 좋을 듯.
    func takeSnapshotImageOfHiddenView() -> UIImage? {
        self.layoutIfNeeded()
        self.alpha = 1
        let renderer = UIGraphicsImageRenderer(bounds: self.bounds)
        let image = renderer.image { context in
            self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        }
        self.alpha = 0
        return image
    }
    
    func takeSnapshotOfHiddenView() -> UIView {
        let image = self.takeSnapshotImageOfHiddenView()
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleToFill
        return imageView
    }
    
}
