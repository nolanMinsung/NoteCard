//
//  MemoMakingView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

final class MemoDetailView: UIView {
    
    
    let blurAnimator = UIViewPropertyAnimator(duration: 0.5, curve: .linear)
    
    var isSpreaded: Bool = false
    
    lazy var titleTextField: UITextField = {
        let textField = UITextField()
        
        let bar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let hideKeyboardButton = UIBarButtonItem(image: UIImage(systemName: "keyboard.chevron.compact.down"),
                                                 style: .plain,
                                                 target: self,
                                                 action: #selector(keyboardHideButtonTapped))
        let flexibleBarButton = UIBarButtonItem(systemItem: UIBarButtonItem.SystemItem.flexibleSpace)
        bar.items = [flexibleBarButton, hideKeyboardButton]
        bar.sizeToFit()
        bar.tintColor = .currentTheme()
        textField.inputAccessoryView = bar
        
        textField.backgroundColor = .detailViewTitleTextFieldBackground
        textField.layer.cornerRadius = 15
        textField.layer.cornerCurve = .continuous
        textField.tintColor = UIColor.currentTheme()
        textField.font = UIFont.systemFont(ofSize: 20)
        textField.placeholder = "제목 없음".localized()
        textField.textAlignment = NSTextAlignment.left
        textField.tintColor = .currentTheme()
        
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftView = leftView
        textField.leftViewMode = UITextField.ViewMode.always
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    let selectedImageCollectionView: MemoDetailViewSelectedImageCollectionView = {
        let flowLayout = LeftAlignedFlowLayout()
        flowLayout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        flowLayout.itemSize = SizeContainer.detailViewThumbnailSize
        flowLayout.minimumInteritemSpacing = 10
        
        let collectionView = MemoDetailViewSelectedImageCollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.register(MemoDetailViewSelectedImageCell.self, forCellWithReuseIdentifier: MemoDetailViewSelectedImageCell.cellID)
        collectionView.isScrollEnabled = true
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 20)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.clipsToBounds = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicatorView
    }()
    
    let spreadCategoriesButton: UIButton = {
        let button = UIButton(configuration: .plain())
        button.setImage(UIImage(systemName: "chevron.right"), for: UIControl.State.normal)
        button.imageView?.contentMode = .center
        button.setTitle("카테고리".localized(), for: UIControl.State.normal)
        button.configuration?.imagePadding = 5
        button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
        button.tintColor = UIColor.currentTheme()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let blurView: UIVisualEffectView = {
        let view = UIVisualEffectView()
        view.clipsToBounds = true
        view.layer.cornerRadius = 20
        view.layer.cornerCurve = .continuous
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let categoryListCollectionView: UICollectionView = {
        let flowLayout = LeftAlignedFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.estimatedItemSize = CGSize(width: 50, height: 30)
        flowLayout.minimumInteritemSpacing = 5
        
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.register(MemoDetailViewCategoryListCell.self, forCellWithReuseIdentifier: MemoDetailViewCategoryListCell.cellID)
        collectionView.clipsToBounds = true
        collectionView.layer.maskedCorners = CACornerMask(arrayLiteral: .layerMinXMinYCorner, .layerMinXMaxYCorner)
        collectionView.layer.cornerRadius = 16
        collectionView.layer.cornerCurve = .continuous
        collectionView.isScrollEnabled = true
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.allowsMultipleSelection = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    lazy var memoTextView: UITextView = {
        let textView: UITextView
        
        if #available(iOS 16.0, *) {
            textView = UITextView(usingTextLayoutManager: false)
        } else {
            textView = UITextView()
        }
        
        textView.isEditable = true
        textView.backgroundColor = .detailViewMemoTextViewBackground
        textView.textInputView.backgroundColor = .clear
        textView.clipsToBounds = true
        textView.scrollsToTop = true
        textView.tintColor = UIColor.currentTheme()
        textView.layer.cornerRadius = 16
        textView.layer.cornerCurve = .continuous
        textView.textContainerInset = UIEdgeInsets(top: 15, left: 6, bottom: 10, right: 6)
        textView.setLineSpace(with: "메모를 입력하세요.".localized(), lineSpace: 5, font: UIFont.systemFont(ofSize: 15), textColor: UIColor.systemGray4)
        
//        //NSAttributedString.Key 중에는 paragraphStyle이라는 게 있는데, 이는 text 전체(여러 줄)에 걸쳐서 적용되는 글의 속성을 뜻하는 듯.
//        //이 paragraphStyle을 잘 설정해서 글의 좌우정렬, 행간, 들여쓰기 등을 설정할 수 있다.
//        //여기서는 행간을 설정해야 하므로 paragraphStyle에 행간만 설정해 주었음.
//        let mutableParagraphStyle = NSMutableParagraphStyle()
//        mutableParagraphStyle.lineSpacing = 4.5
//        let attributes = [
//            NSAttributedString.Key.paragraphStyle: mutableParagraphStyle,
//            .font: UIFont.systemFont(ofSize: 13.5),
//            .foregroundColor: UIColor.label
//        ]
//        textView.typingAttributes = attributes
        
        let bar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let hideKeyboardButton = UIBarButtonItem(image: UIImage(systemName: "keyboard.chevron.compact.down"), style: .plain, target: self, action: #selector(keyboardHideButtonTapped))
        let flexibleBarButton = UIBarButtonItem(systemItem: UIBarButtonItem.SystemItem.flexibleSpace)
        bar.items = [flexibleBarButton, hideKeyboardButton]
        bar.sizeToFit()
        bar.tintColor = .currentTheme()
        textView.inputAccessoryView = bar
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    lazy var selectedImageCollectionViewTopConstraint = self.selectedImageCollectionView.topAnchor.constraint(equalTo: self.titleTextField.bottomAnchor, constant: 0)
    lazy var selectedImageCollectionViewHeightConstraint = self.selectedImageCollectionView.heightAnchor.constraint(equalToConstant: 0)
    lazy var categoryListCollectionViewCenterYConstraint = self.categoryListCollectionView.centerYAnchor.constraint(equalTo: self.spreadCategoriesButton.centerYAnchor)
    lazy var categoryListCollectionViewTopConstraint = self.categoryListCollectionView.topAnchor.constraint(equalTo: self.selectedImageCollectionView.bottomAnchor, constant: 7)
    lazy var categoryListCollectionViewTrailingConstraint
        = self.categoryListCollectionView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: 0)
    lazy var categoryListCollectionViewHeightConstraint = self.categoryListCollectionView.heightAnchor.constraint(equalToConstant: 32)
    lazy var memoTextViewBottomConstraint = self.memoTextView.bottomAnchor.constraint(equalTo: self.keyboardLayoutGuide.topAnchor, constant: -5)
    lazy var memoTextViewHeightConstraint = self.memoTextView.heightAnchor.constraint(equalToConstant: 300)
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureHierarchy()
        setupUI()
        setupActions()
        setupConstraints()
        setupDelegates()
        setupObserver()
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.blurAnimator.stopAnimation(true)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.endEditing(true)
    }
    
    private func configureHierarchy() {
        self.addSubview(self.titleTextField)
        self.addSubview(self.selectedImageCollectionView)
        self.addSubview(self.activityIndicatorView)
        self.addSubview(self.spreadCategoriesButton)
        self.addSubview(self.memoTextView)
        self.addSubview(self.blurView)
        self.addSubview(self.categoryListCollectionView)
    }
    
    private func setupUI() {
        self.backgroundColor = .detailViewBackground
    }
    
    
    private func setupActions() {
        self.spreadCategoriesButton.addTarget(self, action: #selector(spreadCategoriesButtonTapped), for: UIControl.Event.touchUpInside)
    }
    
    @objc private func spreadCategoriesButtonTapped() {
        if self.categoryListCollectionViewHeightConstraint.constant > 40 {
            self.gatherCategories()
        } else {
            self.spreadCategories()
        }
    }
    
    
    
    private func spreadCategories() {
        self.isSpreaded = true
        self.endEditing(true)
        
        self.categoryListCollectionViewCenterYConstraint.isActive = false
        self.categoryListCollectionViewTopConstraint.isActive = true
        
        self.blurView.alpha = 1
        let spreadingAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
        spreadingAnimator.addAnimations { [weak self] in
            guard let self else { return }
            guard let chevronImageView = self.spreadCategoriesButton.imageView else { fatalError() }
            chevronImageView.transform = CGAffineTransform(rotationAngle: .pi/2)
            
            self.categoryListCollectionViewHeightConstraint.constant = 300
            self.categoryListCollectionViewTrailingConstraint.constant = -10
            self.categoryListCollectionView.layer.maskedCorners = CACornerMask(
                arrayLiteral: .layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner
            )
            self.categoryListCollectionView.layer.cornerRadius = 23
            self.categoryListCollectionView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            self.categoryListCollectionView.backgroundColor = .currentTheme().withAlphaComponent(0.07)
            guard let leftAlignedFlowLayout = self.categoryListCollectionView.collectionViewLayout as? LeftAlignedFlowLayout else { fatalError() }
            leftAlignedFlowLayout.scrollDirection = .vertical
            leftAlignedFlowLayout.invalidateLayout()
            self.layoutIfNeeded()
            self.categoryListCollectionView.setContentOffset(CGPoint(x: -10, y: -10), animated: true)
        }
        
        self.blurAnimator.addAnimations { [weak self] in
            guard let self else { return }
            self.blurView.effect = UIBlurEffect(style: UIBlurEffect.Style.systemUltraThinMaterial)
        }
        
        spreadingAnimator.startAnimation()
        self.blurAnimator.startAnimation()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25, execute: self.blurAnimator.pauseAnimation)
    }
    
    
    
    private func gatherCategories() {
        self.isSpreaded = false
        let scrollAnimator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1)
        let gatheringAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
        
        scrollAnimator.addAnimations { [weak self] in
            print("animation")
            guard let self else { fatalError() }
            guard let chevronImageView = self.spreadCategoriesButton.imageView else { fatalError() }
            chevronImageView.transform = CGAffineTransform.identity
            self.categoryListCollectionView.setContentOffset(CGPoint(x: -10, y: -10), animated: false)
        }
        
        scrollAnimator.addCompletion { position in
            print("completion")
            gatheringAnimator.startAnimation()
        }
        
        gatheringAnimator.addAnimations { [weak self] in
            guard let self else { return }
            guard let chevronImageView = self.spreadCategoriesButton.imageView else { fatalError() }
            chevronImageView.transform = CGAffineTransform.identity
            
            self.blurAnimator.stopAnimation(true)
            self.blurView.alpha = 0
            
            self.categoryListCollectionViewTopConstraint.isActive = false
            self.categoryListCollectionViewCenterYConstraint.isActive = true
            
            self.categoryListCollectionViewHeightConstraint.constant = 32
            self.categoryListCollectionViewTrailingConstraint.constant = 0
            self.categoryListCollectionView.layer.maskedCorners = CACornerMask(arrayLiteral: .layerMinXMinYCorner, .layerMinXMaxYCorner)
            self.categoryListCollectionView.layer.cornerRadius = 15
            self.categoryListCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            self.categoryListCollectionView.backgroundColor = .clear
            guard let leftAlignedFlowLayout = self.categoryListCollectionView.collectionViewLayout as? LeftAlignedFlowLayout else { fatalError() }
            leftAlignedFlowLayout.scrollDirection = .horizontal
            leftAlignedFlowLayout.invalidateLayout()
            self.layoutIfNeeded()
        }
        
        
        if self.categoryListCollectionView.contentOffset.y < 30 {
            gatheringAnimator.startAnimation()
        } else {
            scrollAnimator.startAnimation()
        }
    }
    
    
    private func setupConstraints() {
        
        self.titleTextField.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 5).isActive = true
        self.titleTextField.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 10).isActive = true
        self.titleTextField.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
        self.titleTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
//        self.selectedImageCollectionView.topAnchor.constraint(equalTo: self.titleTextField.bottomAnchor, constant: 17).isActive = true
        self.selectedImageCollectionViewTopConstraint.isActive = true
        self.selectedImageCollectionView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
        self.selectedImageCollectionView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
        self.selectedImageCollectionViewHeightConstraint.isActive = true
        
        self.activityIndicatorView.centerXAnchor.constraint(equalTo: self.selectedImageCollectionView.centerXAnchor, constant: 0).isActive = true
        self.activityIndicatorView.centerYAnchor.constraint(equalTo: self.selectedImageCollectionView.centerYAnchor, constant: 0).isActive = true
        
        self.blurView.topAnchor.constraint(equalTo: self.categoryListCollectionView.topAnchor, constant: 0).isActive = true
        self.blurView.leadingAnchor.constraint(equalTo: self.categoryListCollectionView.leadingAnchor, constant: 0).isActive = true
        self.blurView.trailingAnchor.constraint(equalTo: self.categoryListCollectionView.trailingAnchor, constant: 0).isActive = true
        self.blurView.bottomAnchor.constraint(equalTo: self.categoryListCollectionView.bottomAnchor, constant: 0).isActive = true
        
        self.spreadCategoriesButton.topAnchor.constraint(equalTo: self.selectedImageCollectionView.bottomAnchor, constant: 7).isActive = true
        self.spreadCategoriesButton.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 10).isActive = true
        self.spreadCategoriesButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        self.categoryListCollectionViewCenterYConstraint.isActive = true
        //self.categoryListCollectionViewTopConstraint.isActive = true
        self.categoryListCollectionView.leadingAnchor.constraint(equalTo: self.spreadCategoriesButton.trailingAnchor, constant: 0).isActive = true
        //self.categoryListCollectionView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
        self.categoryListCollectionViewTrailingConstraint.isActive = true
        self.categoryListCollectionViewHeightConstraint.isActive = true
        //self.categoryListCollectionView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        
        self.memoTextView.topAnchor.constraint(equalTo: self.spreadCategoriesButton.bottomAnchor, constant: 7).isActive = true
        self.memoTextView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 10).isActive = true
        self.memoTextView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
        self.memoTextViewHeightConstraint.priority = UILayoutPriority(751)
        self.memoTextViewHeightConstraint.isActive = true
        self.memoTextViewBottomConstraint.isActive = true
    }
    
    
    private func setupDelegates() {
        self.titleTextField.delegate = self
        self.memoTextView.delegate = self
    }
    
    
    private func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIApplication.keyboardWillHideNotification, object: nil)
    }
    
    
    @objc func keyboardWillShow() {
        
        if self.isSpreaded {
            self.gatherCategories()
        }
        
        if self.titleTextField.isFirstResponder { return }
        
        guard let screenSize = UIScreen.current?.bounds.size else { fatalError() }
        let aspectRatio = screenSize.height / screenSize.width
        
        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
        animator.addAnimations { [weak self] in
            guard let self else { fatalError() }
            
            if self.selectedImageCollectionView.numberOfSections != 0, aspectRatio < 2 {
//            if let themeColor = UserDefaults.standard.value(forKey: KeysForUserDefaults.themeColor.rawValue) as? String, themeColor == ThemeColor.blue.rawValue {
                self.selectedImageCollectionViewTopConstraint.constant = 0
                self.selectedImageCollectionViewHeightConstraint.constant = 0
                self.layoutIfNeeded()
            }
        }
        
        animator.startAnimation()
    }
    
    
    @objc func keyboardWillHide() {
        guard let screenSize = UIScreen.current?.bounds.size else { fatalError() }
        let aspectRatio = screenSize.height / screenSize.width
        guard self.selectedImageCollectionView.numberOfSections != 0 else { return }
        
        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
        animator.addAnimations { [weak self] in
            guard let self else { fatalError() }
            if self.selectedImageCollectionView.numberOfSections != 0, aspectRatio < 2 {
//            if let themeColor = UserDefaults.standard.value(forKey: KeysForUserDefaults.themeColor.rawValue) as? String, themeColor == ThemeColor.blue.rawValue {
                self.selectedImageCollectionViewTopConstraint.constant = 17
                self.selectedImageCollectionViewHeightConstraint.constant = SizeContainer.detailViewThumbnailSize.height
                self.layoutIfNeeded()
            }
        }
        
        animator.startAnimation()
//        if self.selectedImageCollectionView.numberOfItems(inSection: 0) != 0 {
//            UIView.animate(withDuration: 0.5) {
////                self.selectedImageCollectionViewHeightConstraint.constant = 120
//                self.layoutIfNeeded()
//            }
//        } else {
//            return
//        }
    }
    
    @objc private func keyboardHideButtonTapped() {
        self.endEditing(true)
    }
    
    
}


extension MemoDetailView: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
//        self.gatherCategories()
        
//        if self.categoryListCollectionViewHeightConstraint.constant > 40 {
//            self.gatherCategories()
//        } else {
//            //self.spreadCategories()
//            return
//        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}



extension MemoDetailView: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
//        self.gatherCategories()
        
//        if self.categoryListCollectionViewHeightConstraint.constant > 40 {
//            self.gatherCategories()
//        } else {
//            //self.spreadCategories()
//            return
//        }
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if textView.textColor == UIColor.systemGray4 {
            textView.text = ""
            
            //NSAttributedString.Key 중에는 paragraphStyle이라는 게 있는데, 이는 text 전체(여러 줄)에 걸쳐서 적용되는 글의 속성을 뜻하는 듯.
            //이 paragraphStyle을 잘 설정해서 글의 좌우정렬, 행간, 들여쓰기 등을 설정할 수 있다.
            //여기서는 행간을 설정해야 하므로 paragraphStyle에 행간만 설정해 주었음.
            let mutableParagraphStyle = NSMutableParagraphStyle()
            mutableParagraphStyle.lineSpacing = 5
            let attributes = [
                NSAttributedString.Key.paragraphStyle: mutableParagraphStyle,
                .font: UIFont.systemFont(ofSize: 15),
                .foregroundColor: UIColor.label
            ]
            textView.typingAttributes = attributes
            
            return true
        } else {
            return true
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        print(#function)
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.lineSpacing = 5
        let attributes = [
            NSAttributedString.Key.paragraphStyle: mutableParagraphStyle,
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.label
        ]
        textView.typingAttributes = attributes
        if textView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == "" {
            
            textView.setLineSpace(with: "메모 내용이 없습니다.".localized(), lineSpace: 5, font: UIFont.systemFont(ofSize: 15), textColor: .systemGray4)
        }
    }
}
