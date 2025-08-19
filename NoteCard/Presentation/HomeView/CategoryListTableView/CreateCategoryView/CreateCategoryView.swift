//
//  CreateCategoryView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit


final class CreateCategoryView: UIView {
    
    let categoryNameTextField: InsetTextField = {
        let textField = InsetTextField(top: 0, left: 10, bottom: 0, right: 0)
        textField.placeholder = "카테고리 이름 입력".localized()
        textField.borderStyle = UITextField.BorderStyle.none
        textField.clipsToBounds = true
        textField.layer.cornerRadius = 10
        textField.layer.cornerCurve = .continuous
        textField.backgroundColor = UIColor.createCategoryTextField
        textField.tintColor = .currentTheme
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.endEditing(true)
    }
    
    private func setupUI() {
        self.backgroundColor = UIColor.systemGray6
        self.addSubview(categoryNameTextField)
    }
    
    private func setupConstraints() {
        self.categoryNameTextField.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        self.categoryNameTextField.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 13).isActive = true
        self.categoryNameTextField.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -13).isActive = true
        self.categoryNameTextField.heightAnchor.constraint(equalToConstant: 45).isActive = true
    }
    
}
