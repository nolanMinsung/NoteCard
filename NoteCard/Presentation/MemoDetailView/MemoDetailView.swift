//
//  MemoMakingView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

final class MemoDetailView: UIView {
    
    private let blurAnimator = UIViewPropertyAnimator(duration: 0.5, curve: .linear)
    private let imageShowingAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
    
    private var isCatgorySpreaded: Bool = false
    
    let titleTextField = UITextField()
    let imageCollectionView = MemoDetailViewSelectedImageCollectionView()
    
    private let activityIndicatorView = UIActivityIndicatorView()
    private let categoryButton = UIButton(configuration: .plain())
    private let collectionViewBackgroundBlurView = UIVisualEffectView()
    
    let categoryListCollectionView = CategoryListCollectionView()
    
    let memoTextView: UITextView = {
        if #available(iOS 16.0, *) {
            return UITextView(usingTextLayoutManager: false)
        } else {
            return UITextView()
        }
    }()
    
    // MARK: NSLayoutConstraint Instances
    
    private lazy var imageCollectionViewTopConstraint =
    self.imageCollectionView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 0)
    
    private lazy var imageCollectionViewHeightConstraint =
    self.imageCollectionView.heightAnchor.constraint(equalToConstant: 0)
    
    private lazy var categoryListCollectionViewCenterYConstraint =
    self.categoryListCollectionView.centerYAnchor.constraint(equalTo: categoryButton.centerYAnchor)
    
    private lazy var categoryListCollectionViewTopConstraint =
    self.categoryListCollectionView.topAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: 7)
    
    private lazy var categoryListCollectionViewTrailingConstraint =
    self.categoryListCollectionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: 0)
    
    private lazy var categoryListCollectionViewHeightConstraint =
    self.categoryListCollectionView.heightAnchor.constraint(equalToConstant: 32)
    
    private lazy var memoTextViewBottomConstraintToKeyboard =
    self.memoTextView.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor, constant: -5)
    
    private lazy var memoTextViewBottomConstraintToSafeArea =
    self.memoTextView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -5)
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureViewHierarchy()
        initialSettings()
        setupActions()
        setupLayoutConstraints()
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
    
    private func configureViewHierarchy() {
        self.addSubview(titleTextField)
        self.addSubview(imageCollectionView)
        self.addSubview(activityIndicatorView)
        self.addSubview(categoryButton)
        self.addSubview(memoTextView)
        self.addSubview(collectionViewBackgroundBlurView)
        self.addSubview(categoryListCollectionView)
    }
    
    private func initialSettings() {
        self.backgroundColor = .detailViewBackground
        setupTitleTextField()
        setupTitleTextFieldInputAccessoryView()
        setupSelectedImageCollectionView()
        setupTextView()
        setupTextViewInputAccessories()
        setupCategoryButton()
        setupCollectionViewBackgroundBlurView()
    }
    
    private func setupActions() {
        self.categoryButton.addTarget(
            self,
            action: #selector(spreadCategoriesButtonTapped),
            for: .touchUpInside
        )
    }
    
    @objc private func spreadCategoriesButtonTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
    }
    
    private func spreadCategories() {
        self.isCatgorySpreaded = true
        self.endEditing(true)
        
        self.categoryListCollectionViewCenterYConstraint.isActive = false
        self.categoryListCollectionViewTopConstraint.isActive = true
        
        self.collectionViewBackgroundBlurView.alpha = 1
        let spreadingAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
        spreadingAnimator.addAnimations { [weak self] in
            guard let self else { return }
            
            self.categoryListCollectionViewHeightConstraint.constant = 300
            self.categoryListCollectionViewTrailingConstraint.constant = -10
            self.categoryListCollectionView.layer.maskedCorners = CACornerMask(
                arrayLiteral: .layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner
            )
            self.categoryListCollectionView.layer.cornerRadius = 23
            self.categoryListCollectionView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            self.categoryListCollectionView.backgroundColor = .currentTheme.withAlphaComponent(0.07)
            guard let leftAlignedFlowLayout = self.categoryListCollectionView.collectionViewLayout as? LeftAlignedFlowLayout else { fatalError() }
            leftAlignedFlowLayout.scrollDirection = .vertical
            leftAlignedFlowLayout.invalidateLayout()
            self.layoutIfNeeded()
            self.categoryListCollectionView.setContentOffset(CGPoint(x: -10, y: -10), animated: true)
        }
        
        self.blurAnimator.addAnimations { [weak self] in
            guard let self else { return }
            self.collectionViewBackgroundBlurView.effect = UIBlurEffect(style: UIBlurEffect.Style.systemUltraThinMaterial)
        }
        
        spreadingAnimator.startAnimation()
        self.blurAnimator.startAnimation()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25, execute: self.blurAnimator.pauseAnimation)
    }
    
    private func gatherCategories() {
        self.isCatgorySpreaded = false
        self.categoryButton.isSelected = false
        let scrollAnimator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1)
        let gatheringAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
        
        scrollAnimator.addAnimations { [weak self] in
            guard let self else { fatalError() }
            self.categoryListCollectionView.setContentOffset(CGPoint(x: -10, y: -10), animated: false)
        }
        
        scrollAnimator.addCompletion { position in
            gatheringAnimator.startAnimation()
        }
        
        gatheringAnimator.addAnimations { [weak self] in
            guard let self else { return }
            
            self.blurAnimator.stopAnimation(true)
            self.collectionViewBackgroundBlurView.alpha = 0
            
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
    
    private func setupLayoutConstraints() {
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 5),
            titleTextField.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
            titleTextField.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
            titleTextField.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        imageCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageCollectionViewTopConstraint,
            imageCollectionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 0),
            imageCollectionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: 0),
            imageCollectionViewHeightConstraint,
        ])
        
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: imageCollectionView.centerXAnchor, constant: 0),
            activityIndicatorView.centerYAnchor.constraint(equalTo: imageCollectionView.centerYAnchor, constant: 0),
        ])
        
        collectionViewBackgroundBlurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionViewBackgroundBlurView.topAnchor.constraint(equalTo: categoryListCollectionView.topAnchor, constant: 0),
            collectionViewBackgroundBlurView.leadingAnchor.constraint(equalTo: categoryListCollectionView.leadingAnchor, constant: 0),
            collectionViewBackgroundBlurView.trailingAnchor.constraint(equalTo: categoryListCollectionView.trailingAnchor, constant: 0),
            collectionViewBackgroundBlurView.bottomAnchor.constraint(equalTo: categoryListCollectionView.bottomAnchor, constant: 0),
        ])
        
        categoryButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            categoryButton.topAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: 7),
            categoryButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
            categoryButton.heightAnchor.constraint(equalToConstant: 40),
        ])
        
        categoryListCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            categoryListCollectionViewCenterYConstraint,
            categoryListCollectionView.leadingAnchor.constraint(equalTo: categoryButton.trailingAnchor, constant: 0),
            categoryListCollectionViewTrailingConstraint,
            categoryListCollectionViewHeightConstraint,
        ])
        
        memoTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            memoTextView.topAnchor.constraint(equalTo: categoryButton.bottomAnchor, constant: 7),
            memoTextView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 10),
            memoTextView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -10),
            memoTextViewBottomConstraintToKeyboard,
        ])
        memoTextViewBottomConstraintToSafeArea.isActive = false
    }
    
    private func setupDelegates() {
        self.titleTextField.delegate = self
        self.memoTextView.delegate = self
    }
    
    private func setupObserver() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow),
            name: UIApplication.keyboardWillShowNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide),
            name: UIApplication.keyboardWillHideNotification, object: nil
        )
    }
    
    @objc func keyboardWillShow() {
        if self.isCatgorySpreaded {
            self.gatherCategories()
        }
        
        if self.titleTextField.isFirstResponder { return }
        
        guard let screenSize = UIScreen.current?.bounds.size else { fatalError() }
        let aspectRatio = screenSize.height / screenSize.width
        let isImageEmpty = imageCollectionView.numberOfSections == 0
        
        // 키보드가 올라올 때 이미지가 접히는 기준: 이미지가 존재하는데, 홈 버튼이 있는 아이폰 비율일 때
        if !isImageEmpty &&  aspectRatio < 2 {
            UIView.springAnimate(withDuration: 0.5) { [weak self] in
                self?.imageCollectionViewTopConstraint.constant = 0
                self?.imageCollectionViewHeightConstraint.constant = 0
                self?.layoutIfNeeded()
            }
        }
    }
    
    @objc func keyboardWillHide() {
        guard let screenSize = UIScreen.current?.bounds.size else { fatalError() }
        let aspectRatio = screenSize.height / screenSize.width
        guard self.imageCollectionView.numberOfSections != 0 else { return }
        
        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
        animator.addAnimations { [weak self] in
            guard let self else { fatalError() }
            if self.imageCollectionView.numberOfSections != 0, aspectRatio < 2 {
                self.imageCollectionViewTopConstraint.constant = 17
                self.imageCollectionViewHeightConstraint.constant = CGSizeConstant.detailViewThumbnailSize.height
                self.layoutIfNeeded()
            }
        }
        animator.startAnimation()
    }
    
    @objc private func keyboardHideButtonTapped() {
        self.endEditing(true)
    }
    
}


// 이미지 목록 띄우기/숨기기
extension MemoDetailView {
    
    /// 이미지 영역을 보이도록 함.
    /// - Parameters:
    ///   - targetHeight: 이미지를 띄울 컬렉션 뷰 높이.
    ///   - animated: 애니메이션 적용 여부
    func showImageCollectionView(targetHeight: CGFloat, animated: Bool = true) {
        imageShowingAnimator.stopAnimation(true)
        imageShowingAnimator.addAnimations { [weak self] in
            self?.imageCollectionViewTopConstraint.constant = 17
            self?.imageCollectionViewHeightConstraint.constant = targetHeight
        }
        imageShowingAnimator.startAnimation()
    }
    
    /// 이미지 영역을 숨김.
    /// - Parameter animated: 애니메이션 적용 여부
    func hideImageCollectionView(animated: Bool = true) {
        imageShowingAnimator.stopAnimation(true)
        imageShowingAnimator.addAnimations { [weak self] in
            self?.imageCollectionViewTopConstraint.constant = 0
            self?.imageCollectionViewHeightConstraint.constant = 0
            
            self?.layoutIfNeeded()
        }
        imageShowingAnimator.startAnimation()
    }
    
    /// 이미지 띄우는 목록 로딩 인디케이터 표시
    func startImageCollectionViewLoading() {
        self.activityIndicatorView.startAnimating()
    }
    
    /// 이미지 띄우는 목록 로딩 인디케이터 숨김.
    func stopImageCollectionViewLoading() {
        self.activityIndicatorView.stopAnimating()
    }
    
}


extension MemoDetailView: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}



extension MemoDetailView: UITextViewDelegate {
    
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


// MARK: - Initial Settings
extension MemoDetailView {
    
    private func setupTitleTextField() {
        titleTextField.backgroundColor = .detailViewTitleTextFieldBackground
        titleTextField.layer.cornerRadius = 15
        titleTextField.layer.cornerCurve = .continuous
        titleTextField.tintColor = UIColor.currentTheme
        titleTextField.font = UIFont.systemFont(ofSize: 20)
        titleTextField.placeholder = "제목 없음".localized()
        titleTextField.textAlignment = NSTextAlignment.left
        titleTextField.tintColor = .currentTheme
        
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        titleTextField.leftView = leftView
        titleTextField.leftViewMode = UITextField.ViewMode.always
    }
    
    private func setupTitleTextFieldInputAccessoryView() {
        let bar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
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
        titleTextField.inputAccessoryView = bar
    }
    
    private func setupSelectedImageCollectionView() {
        imageCollectionView.register(
            MemoDetailViewSelectedImageCell.self,
            forCellWithReuseIdentifier: MemoDetailViewSelectedImageCell.cellID
        )
        imageCollectionView.isScrollEnabled = true
        imageCollectionView.backgroundColor = .clear
        imageCollectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 20)
        imageCollectionView.showsHorizontalScrollIndicator = false
        imageCollectionView.showsVerticalScrollIndicator = false
        imageCollectionView.clipsToBounds = false
    }
    
    private func setupTextView() {
        memoTextView.isEditable = true
        memoTextView.backgroundColor = .detailViewMemoTextViewBackground
        memoTextView.textInputView.backgroundColor = .clear
        memoTextView.clipsToBounds = true
        memoTextView.scrollsToTop = true
        memoTextView.tintColor = .currentTheme
        memoTextView.layer.cornerRadius = 16
        memoTextView.layer.cornerCurve = .continuous
        memoTextView.textContainerInset = UIEdgeInsets(top: 15, left: 6, bottom: 10, right: 6)
        memoTextView.setLineSpace(
            with: "메모를 입력하세요.".localized(),
            lineSpace: 5,
            font: UIFont.systemFont(ofSize: 15)
        )
    }
    
    private func setupTextViewInputAccessories() {
        let bar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let hideKeyboardButton = UIBarButtonItem(
            image: UIImage(systemName: "keyboard.chevron.compact.down"),
            style: .plain,
            target: self,
            action: #selector(keyboardHideButtonTapped)
        )
        let flexibleBarButton = UIBarButtonItem(systemItem: .flexibleSpace)
        bar.items = [flexibleBarButton, hideKeyboardButton]
        bar.sizeToFit()
        bar.tintColor = .currentTheme
        memoTextView.inputAccessoryView = bar
    }
    
    private func setupCategoryButton() {
        var config = UIButton.Configuration.plain()
        config.baseBackgroundColor = .clear
        config.baseForegroundColor = .currentTheme
        config.image = UIImage(systemName: "chevron.right")
        config.title = "카테고리".localized()
        config.imagePadding = 5
        config.contentInsets = .init(top: 0, leading: 5, bottom: 0, trailing: 5)
        
        categoryButton.configuration = config
        // chevron 이미지 회전 시 비율 깨지지 않도록
        categoryButton.imageView?.contentMode = .center
        categoryButton.configurationUpdateHandler = { [weak self] button in
            if button.isSelected {
                UIView.springAnimate(withDuration: 0.5) {
                    button.imageView?.transform = .init(rotationAngle: .pi/2)
                    self?.spreadCategories()
                }
            } else {
                UIView.springAnimate(withDuration: 0.5) {
                    button.imageView?.transform = .identity
                    self?.gatherCategories()
                }
            }
        }
    }
    
    private func setupCollectionViewBackgroundBlurView() {
        collectionViewBackgroundBlurView.clipsToBounds = true
        collectionViewBackgroundBlurView.layer.cornerRadius = 20
        collectionViewBackgroundBlurView.layer.cornerCurve = .continuous
    }
    
}


extension MemoDetailView {
    
    // nested type 정의
    
    final class CategoryListCollectionView: UICollectionView {
        
        init() {
            let leftAlignedFlowLayout = LeftAlignedFlowLayout()
            leftAlignedFlowLayout.scrollDirection = .horizontal
            leftAlignedFlowLayout.estimatedItemSize = CGSize(width: 50, height: 30)
            leftAlignedFlowLayout.minimumInteritemSpacing = 5
            
            super.init(frame: .zero, collectionViewLayout: leftAlignedFlowLayout)
            
            self.register(MemoDetailViewCategoryListCell.self, forCellWithReuseIdentifier: MemoDetailViewCategoryListCell.cellID)
            self.layer.maskedCorners = CACornerMask(arrayLiteral: .layerMinXMinYCorner, .layerMinXMaxYCorner)
            self.layer.cornerRadius = 16
            self.layer.cornerCurve = .continuous
            self.clipsToBounds = true
            self.isScrollEnabled = true
            self.backgroundColor = .clear
            self.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            self.allowsMultipleSelection = true
            self.showsHorizontalScrollIndicator = false
            self.showsVerticalScrollIndicator = false
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
}


extension MemoDetailView {
    
    func prepareForDismissal() {
        memoTextViewBottomConstraintToKeyboard.isActive = false
        memoTextViewBottomConstraintToSafeArea.isActive = true
    }
    
}
