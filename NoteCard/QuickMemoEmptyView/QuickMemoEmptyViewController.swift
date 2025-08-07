//
//  QuickMemoEmptyViewController.swift
//  NoteCard
//
//  Created by 김민성 on 2024/01/29.
//

import UIKit

class QuickMemoEmptyViewController: UIViewController {
    
    lazy var quickMemoEnptyView = self.view as! QuickMemoEmptyView
    
    override func loadView() {
        self.view = QuickMemoEmptyView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
}
