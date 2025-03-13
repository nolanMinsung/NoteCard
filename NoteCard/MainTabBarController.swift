//
//  MainTabBarController.swift
//  NoteCard
//
//  Created by 김민성 on 2024/01/30.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    var previousSelectedIndex: Int = 0
    
    var isUncategorizedMemoVCHasShown: Bool = false
    
    var blurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: nil)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        return blurView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureHierarchy()
        setupConstraints()
    }
    
    private func configureHierarchy() {
        self.view.addSubview(self.blurView)
    }
    
    private func setupConstraints() {
        self.blurView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0).isActive = true
        self.blurView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0).isActive = true
        self.blurView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0).isActive = true
        self.blurView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0).isActive = true
    }
    
    
}
