//
//  HomeHeaderButton.swift
//  NoteCard
//
//  Created by 김민성 on 4/6/25.
//

import UIKit

final class HomeHeaderButton: UIButton, Shrinkable {
    var shrinkingAnimator = UIViewPropertyAnimator(duration: 0.2, dampingRatio: 1)
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                shrink(scale: 0.9)
            } else {
                expand()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "chevron.right")
        configuration.imagePlacement = NSDirectionalRectEdge.trailing
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        self.configuration = configuration
        
        tintColor = UIColor.label
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
