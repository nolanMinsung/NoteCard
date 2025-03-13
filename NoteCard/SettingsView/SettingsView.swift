//
//  SettingsView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/16.
//

import UIKit

final class SettingsView: UIView {
    
    
    let settingsTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: UITableView.Style.insetGrouped)
        tableView.register(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.cellID)
        tableView.contentInset.top = 0
        tableView.contentInset.top = 17
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        setupUI()
        setupConstraints()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    private func setupUI() {
        self.backgroundColor = .systemBackground
        
        self.addSubview(settingsTableView)
    }
    
    private func setupConstraints() {
        self.settingsTableView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        self.settingsTableView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
        self.settingsTableView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
        self.settingsTableView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
    }
    
}
