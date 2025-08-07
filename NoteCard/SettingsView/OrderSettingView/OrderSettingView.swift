//
//  DateTimeSettingView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/12/27.
//

import UIKit

final class OrderSettingView: UIView {
    
    let orderSettingTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: UITableView.Style.insetGrouped)
        tableView.register(OrderSettingTableViewCell.self, forCellReuseIdentifier: OrderSettingTableViewCell.cellID)
        tableView.allowsMultipleSelection = true
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
        self.addSubview(self.orderSettingTableView)
    }
    
    private func setupConstraints() {
        self.orderSettingTableView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        self.orderSettingTableView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
        self.orderSettingTableView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
        self.orderSettingTableView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
    }
    
}


