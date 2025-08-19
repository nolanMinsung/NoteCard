//
//  CategoryListView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/20.
//

import UIKit

final class CategoryListView: UIView {
    
    let categoryListTableView: UITableView = {
        let view = UITableView(frame: .zero, style: UITableView.Style.grouped)
        view.register(CategoryListTableViewCell.self, forCellReuseIdentifier: CategoryListTableViewCell.cellID)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        self.addSubview(self.categoryListTableView)
    }
    
    private func setupConstraints() {
        self.categoryListTableView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        self.categoryListTableView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0).isActive = true
        self.categoryListTableView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0).isActive = true
        self.categoryListTableView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
    }
    
}
