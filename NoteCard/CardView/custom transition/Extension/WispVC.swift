//
//  WispVC.swift
//  NoteCard
//
//  Created by 김민성 on 7/26/25.
//

import UIKit


final class WispVC: CardViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rootView.memoTextView.delegate = self
    }
    
    
}


extension WispVC: UITextViewDelegate {
    
    
    
}
