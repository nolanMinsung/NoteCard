//
//  SearchBar.swift
//  NoteCard
//
//  Created by 김민성 on 8/6/25.
//

import UIKit

final class SearchBar: UIView {
    
    let searchTextField = UITextField()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let leftView = UIView()
        let leftImageView = UIImageView(image: .init(systemName: "magnifyingglass"))
        leftView.frame = .init(origin: .zero, size: .init(width: 35, height: 20))
        leftView.addSubview(leftImageView)
        leftImageView.contentMode = .scaleAspectFit
        leftImageView.frame = leftView.bounds
        
        // UIImageView를 직접 넣으면 frame 적용이 안 됨. UIView 안에 subview로 UIImageView를 넣으면 frame이 적용됨.
        searchTextField.leftView = leftView
        searchTextField.leftViewMode = .always
        searchTextField.layer.cornerRadius = 10
        searchTextField.layer.cornerCurve = .continuous
        searchTextField.backgroundColor = .systemBackground
        searchTextField.placeholder = "검색"
        
        addSubview(searchTextField)
        
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchTextField.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            searchTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            searchTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            searchTextField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            searchTextField.heightAnchor.constraint(equalToConstant: 35),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
