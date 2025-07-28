//
//  WispViewController.swift
//  NoteCard
//
//  Created by 김민성 on 7/28/25.
//

import UIKit

class WispViewController: UIViewController, WispDismissable {
    
    var viewInset: NSDirectionalEdgeInsets// = .init(top: 130, leading: 10, bottom: 130, trailing: 10)
    
    init(viewInset: NSDirectionalEdgeInsets) {
        self.viewInset = viewInset
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemGray4
    }
    
}
