//
//  SettingsPlaceholderViewController.swift
//  NoteCard
//
//  Created by 김민성 on 12/11/25.
//

import UIKit
import Domain
import DesignSystem
import Shared

public final class SettingsPlaceholderViewController: UIViewController {

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = L10n.Settings.placeholderText
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
