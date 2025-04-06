//
//  HomeHeaderView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class HomeHeaderView: UICollectionReusableView, ReuseIdentifiable {
    
    var section: Int = 0
    
    let button = HomeHeaderButton()
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textAlignment = NSTextAlignment.center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.addSubview(button)
    }
    
    func setupConstraints() {
        self.heightAnchor.constraint(equalToConstant: 44).isActive = true
        self.button.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20).isActive = true
        self.button.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0).isActive = true
    }
    
    private func setupActions() {
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    @objc private func buttonTapped() {
        NotificationCenter.default.post(name: NSNotification.Name("headerTapped"), object: self)
    }
    
    override func prepareForReuse() {
        self.button.tintColor = UIColor.currentTheme()
    }
    
}

