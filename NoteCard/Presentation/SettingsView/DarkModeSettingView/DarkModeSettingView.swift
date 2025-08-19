//
//  ThemeColorPickingView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/12/20.
//

import UIKit


final class DarkModeSettingView: UIView {
    
    let darkModeSettingTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: UITableView.Style.insetGrouped)
        tableView.register(DarkModeSettingTableViewCell.self, forCellReuseIdentifier: DarkModeSettingTableViewCell.cellID)
        tableView.contentInset.top = -20
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
        
        self.addSubview(darkModeSettingTableView)
    }
    
    private func setupConstraints() {
        self.darkModeSettingTableView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        self.darkModeSettingTableView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
        self.darkModeSettingTableView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
        self.darkModeSettingTableView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
    }
    
}
