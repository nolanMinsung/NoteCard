//
//  HomeHeaderView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class HomeHeaderView: UICollectionReusableView {
    
    let button = HomeHeaderButton()
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViewHierarchy()
        setupLayoutConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViewHierarchy() {
        self.addSubview(button)
    }
    
    private func setupLayoutConstraints() {
        NSLayoutConstraint.activate([
            self.heightAnchor.constraint(equalToConstant: 44),
            self.button.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            self.button.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0)
        ])
    }
    
}

