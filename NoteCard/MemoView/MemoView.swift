//
//  CardView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit


final class MemoView: UIView {
    
    let categoryManager = CategoryEntityManager.shared
    let memoManager = MemoEntityManager.shared
    
    let categoryNameTextField = UITextField()
    let segmentedControl = UISegmentedControl(
        items: [UIImage(systemName: "rectangle.portrait.arrowtriangle.2.outward")!,
                UIImage(systemName: "rectangle.grid.3x2")!]
    )
    
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
    let viewUnderNaviBar = UIView()
    let largeCardCollectionView = LargeCardCollectionView()
    let smallCardCollectionView = SmallCardCollectionView()
    
    // MARK: - Layout Constraints
    
    lazy var categoryNameTextFieldTopConstraint
    = self.categoryNameTextField.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 0)
    
    lazy var smallCardCollectionViewBottomConstraint
    = self.smallCardCollectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        configureViewHierarchy()
        setupConstraints()
        setupNotificationObserver()
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
        segmentedControl.selectedSegmentIndex = 0
        viewUnderNaviBar.backgroundColor = .memoViewBackground
        
        smallCardCollectionView.isHidden = UIDevice.current.userInterfaceIdiom == .phone
        largeCardCollectionView.isHidden = !smallCardCollectionView.isHidden
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
        self.addSubview(smallCardCollectionView)
        self.addSubview(blurView)
        self.addSubview(viewUnderNaviBar)
        self.addSubview(categoryNameTextField)
        self.addSubview(segmentedControl)
        self.addSubview(largeCardCollectionView)
    }
    
    func setupConstraints() {
        categoryNameTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            categoryNameTextFieldTopConstraint,
            categoryNameTextField.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            categoryNameTextField.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            categoryNameTextField.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor, constant: 0),
        ])
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: categoryNameTextField.bottomAnchor, constant: 20),
            segmentedControl.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor, constant: 0),
        ])
        
        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            blurView.heightAnchor.constraint(equalToConstant: 200),
        ])
        
        viewUnderNaviBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            viewUnderNaviBar.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            viewUnderNaviBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            viewUnderNaviBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            viewUnderNaviBar.heightAnchor.constraint(equalToConstant: 200),
        ])
        
        largeCardCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            largeCardCollectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 0),
            largeCardCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            largeCardCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            largeCardCollectionView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: 0),
        ])
        
        smallCardCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            smallCardCollectionView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            smallCardCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            smallCardCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            smallCardCollectionViewBottomConstraint,
        ])
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(kayboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func kayboardWillShow() {
        self.largeCardCollectionView.isScrollEnabled = false
    }
    
    @objc private func keyboardWillHide() {
        self.largeCardCollectionView.isScrollEnabled = true
    }
    
    @objc private func keyboardHideButtonTapped() {
        self.endEditing(true)
    }
    
}


