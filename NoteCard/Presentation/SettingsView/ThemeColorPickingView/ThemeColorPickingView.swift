//
//  ThemeColorPickingView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/12/20.
//

import UIKit


final class ThemeColorPickingView: UIView {
    
    let themeColorPickingTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: UITableView.Style.insetGrouped)
        tableView.register(ThemeColorPickingTableViewCell.self, forCellReuseIdentifier: ThemeColorPickingTableViewCell.cellID)
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
        
        self.addSubview(themeColorPickingTableView)
    }
    
    private func setupConstraints() {
        self.themeColorPickingTableView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        self.themeColorPickingTableView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
        self.themeColorPickingTableView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
        self.themeColorPickingTableView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
    }
    
}
