//
//  QuickMemoEmptyView.swift
//  NoteCard
//
//  Created by 김민성 on 2024/01/29.
//

import UIKit

final class QuickMemoEmptyView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.backgroundColor = UIColor.memoViewBackground
    }
    
}
