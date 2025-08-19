//
//  DateTimeSettingView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/12/27.
//

import UIKit

final class TimeFormatSettingView: UIView {
    
    let timeFormatSettingTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: UITableView.Style.insetGrouped)
        tableView.register(TimeFormatSettingTableViewCell.self, forCellReuseIdentifier: TimeFormatSettingTableViewCell.cellID)
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
        self.backgroundColor = .systemGray6
        self.addSubview(self.timeFormatSettingTableView)
    }
    
    private func setupConstraints() {
        self.timeFormatSettingTableView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        self.timeFormatSettingTableView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
        self.timeFormatSettingTableView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
        self.timeFormatSettingTableView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
    }
    
}


