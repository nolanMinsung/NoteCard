//
//  CardViewController.swift
//  NoteCard
//
//  Created by 김민성 on 7/21/25.
//

import UIKit

class CardViewController: UIViewController {
    
    let memoEntity: MemoEntity
    
    let rootView = CardView()
    
    init(memoEntity: MemoEntity) {
        self.memoEntity = memoEntity
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = rootView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rootView.configure(with: memoEntity)
        setupGestures()
    }
        
}


extension CardViewController {
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundBlurTapped))
        rootView.backgroundBlurView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func backgroundBlurTapped(_ sender: UITapGestureRecognizer) {
        dismiss(animated: false)
    }
    
}
