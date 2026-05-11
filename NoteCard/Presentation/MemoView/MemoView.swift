//
//  CardView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit


final class MemoView: UIView {

    let categoryNameTextField = UITextField()
    let smallCardCollectionView = SmallCardCollectionView()
    let editingToolbar = MemoEditingToolbarView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        configureViewHierarchy()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func setupUI() {
        self.clipsToBounds = true
        self.backgroundColor = UIColor.memoViewBackground
        
        setupTextField()
    }
    
    private func setupTextField() {
        categoryNameTextField.placeholder = ""
        categoryNameTextField.borderStyle = .none
        categoryNameTextField.tintColor = .currentTheme
        categoryNameTextField.textAlignment = .center
        categoryNameTextField.font = UIFont.boldSystemFont(ofSize: 35)
        categoryNameTextField.adjustsFontSizeToFitWidth = true
        categoryNameTextField.minimumFontSize = 27
        
        let bar = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        let hideKeyboardButton = UIBarButtonItem(
            image: UIImage(systemName: "keyboard.chevron.compact.down"),
            style: .plain,
            target: self,
            action: #selector(keyboardHideButtonTapped)
        )
        let flexibleBarButton = UIBarButtonItem(systemItem: UIBarButtonItem.SystemItem.flexibleSpace)
        bar.items = [flexibleBarButton, hideKeyboardButton]
        bar.sizeToFit()
        bar.tintColor = .currentTheme
        categoryNameTextField.inputAccessoryView = bar
    }
    
    private func configureViewHierarchy() {
        self.addSubview(categoryNameTextField)
        self.addSubview(smallCardCollectionView)
        self.addSubview(editingToolbar)
    }

    func setupConstraints() {
        categoryNameTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            categoryNameTextField.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 0),
            categoryNameTextField.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            categoryNameTextField.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ])

        smallCardCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            smallCardCollectionView.topAnchor.constraint(equalTo: categoryNameTextField.bottomAnchor, constant: 20),
            smallCardCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            smallCardCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            // 카드가 글래스 탭바/편집 toolbar 뒤로 스크롤되어 깊이감을 살리도록 화면 최하단까지 확장.
            // 콘텐츠가 가려지지 않도록 하는 건 contentInsetAdjustmentBehavior(.automatic)의 safe area 보정 +
            // MemoViewController가 toolbar 가시성에 맞춰 토글하는 contentInset.bottom이 함께 처리한다.
            smallCardCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        ])

        editingToolbar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // 탭바와 떨어진 floating pill로 보이도록 좌우 인셋 + 탭바 위 gap.
            editingToolbar.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            editingToolbar.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            editingToolbar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12),
            editingToolbar.heightAnchor.constraint(equalToConstant: MemoEditingToolbarView.preferredHeight),
        ])
    }
    
    @objc private func keyboardHideButtonTapped() {
        self.endEditing(true)
    }
    
}


