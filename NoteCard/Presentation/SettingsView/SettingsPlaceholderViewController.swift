//
//  SettingsPlaceholderViewController.swift
//  NoteCard
//
//  Created by 김민성 on 12/11/25.
//

import UIKit

class SettingsPlaceholderViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "Settings_Placeholder_text".localized()
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .title2)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
}
