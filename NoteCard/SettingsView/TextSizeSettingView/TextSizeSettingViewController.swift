//
//  TextSizeSettingViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2024/01/01.
//

import UIKit

final class TextSizeSettingViewController: UIViewController {
    
    lazy var textSizeSettingView = self.view as! TextSizeSettingView
    
    override func loadView() {
        self.view = TextSizeSettingView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNaviBar()
    }
    
    private func setupNaviBar() {
        self.title = "메모 글자 크기"
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.navigationBar.tintColor = .currentTheme
    }
    
}

