//
//  PopupCardView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

final class PopupCardView: UIView {
    
    private var memoEntity: MemoEntity?
    private var memo: Memo
    private var isTextFieldChanged: Bool = false
    var isTextViewChanged: Bool = false
    var isEdited: Bool = false
    
    private(set) lazy var imageCollectionViewHeight
    = self.imageCollectionView.heightAnchor.constraint(equalToConstant: 0)
    
    private(set) lazy var memoTextViewBottom
    = self.memoTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
    
    private(set) lazy var memoTextViewBottomToKeyboardTop
    = self.memoTextView.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor, constant: -10)
    
    let titleTextField = UITextField()
    let likeButton = UIButton(configuration: .plain())
    let ellipsisButton = UIButton()
    
    private let makeCategoryFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 10
        flowLayout.scrollDirection = .horizontal
//        flowLayout.estimatedItemSize = CGSize(width: 50, height: 35)
        flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        return flowLayout
    }
    private(set) var categoryCollectionView: UICollectionView!
    
    private let makeImageFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 10
        flowLayout.sectionInset = .zero
        flowLayout.itemSize = CGSize(width: 70, height: 70)
        flowLayout.scrollDirection = .horizontal
        return flowLayout
    }
    var imageCollectionView: UICollectionView!
    
    private(set) var memoTextView: UITextView!
    let memoDateLabel = UILabel()
    
    init(memo: Memo) {
        self.memo = memo
        super.init(frame: .zero)
        setupUI()
        configureHierarchy()
        setupConstraints()
        setupActions()
        setupDelegates()
        configureView(with: memo)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if traitCollection.userInterfaceStyle == .dark {
            layer.shadowPath = nil
            layer.shadowColor = nil
            
        } else {
            let bezierPath = UIBezierPath(rect: self.bounds)
            layer.shadowPath = bezierPath.cgPath
            layer.shadowColor = UIColor.currentTheme.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 0)
            layer.shadowOpacity = 0.25
            layer.shadowRadius = 60
        }
    }
    
    private func setupUI() {
        categoryCollectionView = UICollectionView(frame: .zero, collectionViewLayout: makeCategoryFlowLayout())
        imageCollectionView = UICollectionView(frame: .zero, collectionViewLayout: makeImageFlowLayout())
        
        backgroundColor = UIColor.memoBackground
        layer.cornerCurve = .continuous
        
        setupTitleTextField()
        setupLikeButton()
        setupEllipsisButton()
        setupCategoryCollectionView()
        setupImageCollectionView()
        setupMemoTextView()
        setupMemoDateLabel()
    }
    
    private func configureHierarchy() {
        addSubview(titleTextField)
        addSubview(likeButton)
        addSubview(ellipsisButton)
        addSubview(memoDateLabel)
        addSubview(categoryCollectionView)
        addSubview(imageCollectionView)
        addSubview(memoTextView)
    }
    
    private func setupActions() {
        self.titleTextField.addTarget(self, action: #selector(textFieldDidChagne(_:)), for: UIControl.Event.editingChanged)
    }
    
    @objc private func textFieldDidChagne(_ textField: UITextField) {
        print(#function)
        self.isTextFieldChanged = true
        self.isEdited = true
    }
    
    private func setupDelegates() {
        self.titleTextField.delegate = self
        self.memoTextView.delegate = self
    }
    
    private func setupConstraints() {
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            titleTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            titleTextField.heightAnchor.constraint(equalToConstant: 30),
        ])
        
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            likeButton.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            likeButton.leadingAnchor.constraint(equalTo: titleTextField.trailingAnchor, constant: 10),
            likeButton.trailingAnchor.constraint(equalTo: ellipsisButton.leadingAnchor, constant: 0),
            likeButton.widthAnchor.constraint(equalToConstant: 27),
            likeButton.heightAnchor.constraint(equalToConstant: 27),
        ])
        
        ellipsisButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ellipsisButton.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            ellipsisButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            ellipsisButton.widthAnchor.constraint(equalToConstant: 30),
            ellipsisButton.heightAnchor.constraint(equalToConstant: 30),
        ])
        
        memoDateLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            memoDateLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 10),
            memoDateLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            memoDateLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
        ])
        
        categoryCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            categoryCollectionView.topAnchor.constraint(equalTo: memoDateLabel.bottomAnchor, constant: 10),
            categoryCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            categoryCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 28),
        ])
        
        imageCollectionView.translatesAutoresizingMaskIntoConstraints = false
        imageCollectionViewHeight.priority = UILayoutPriority(751)
        NSLayoutConstraint.activate([
            imageCollectionView.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: 10),
            imageCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            imageCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            imageCollectionViewHeight,
        ])
        
        memoTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            memoTextView.topAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: 10),
            memoTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            memoTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            memoTextViewBottom,
        ])
    }
    
    private func updateTitleTextField() {
        if self.isTextFieldChanged {
            guard let text = self.titleTextField.text else { fatalError() }
            self.memoEntity?.memoTitle = text
            CoreDataStack.shared.saveContext()
        }
    }
    
    func updateMemoTextView() {
        if self.isTextViewChanged {
            Task {
                try await MemoEntityRepository.shared.updateMemoContent(memo, newMemoText: memoTextView.text)
            }
//            self.memoEntity?.memoText = self.memoTextView.text
//            CoreDataStack.shared.saveContext()
        }
    }
    
    
    func configureView(with memo: Memo) {
        guard let orderCriterion = UserDefaults.standard.string(
            forKey: UserDefaultsKeys.orderCriterion.rawValue
        ) else {
            fatalError()
        }
        
        if memo.isInTrash {
            self.memoDateLabel.textColor = .systemRed
            guard let deletedDate = memo.deletedDate else { fatalError() }
            let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
            let dateAfterDeleted = calendar.dateComponents([.day, .hour], from: deletedDate, to: Date())
            guard let dayAfterDeleted = dateAfterDeleted.day else { fatalError() }
            guard let hourAfterDeleted = dateAfterDeleted.hour else { fatalError() }
            
            if dayAfterDeleted < 13 {
                self.memoDateLabel.text = String(format: "%d일 뒤에 삭제됨".localized(), 14 - dayAfterDeleted)
            } else {
                self.memoDateLabel.text = "1일 이내에 삭제됨".localized()
            }
            
            self.likeButton.isEnabled = false
            self.likeButton.tintColor = .lightGray
            self.titleTextField.isEnabled = false
            self.memoTextView.isEditable = false
            
        } else if orderCriterion == OrderCriterion.creationDate.rawValue {
            self.memoDateLabel.text = String(
                format: "%@에 생성됨".localized(),
                memo.creationDate.getCreationDateInString()
            )
        } else {
            self.memoDateLabel.text = String(
                format: "%@에 수정됨".localized(),
                memo.modificationDate.getModificationDateString()
            )
        }
        
        self.titleTextField.text = memo.memoTitle
        self.likeButton.isSelected = memo.isFavorite
        
        self.memoTextView.setLineSpace(with: memo.memoText, lineSpace: 5, font: UIFont.systemFont(ofSize: 15), textColor: .label)
        if UserDefaults.standard.object(forKey: "themeColor") as! String == ThemeColor.black.rawValue {
            self.memoTextView.linkTextAttributes =
            [NSAttributedString.Key.foregroundColor: UIColor.systemGray,
             NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]
        } else {
            self.memoTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.currentTheme]
        }
    }
    
    @objc private func keyboardHideButtonTapped() {
        self.endEditing(true)
    }
    
}


// MARK: - UITextFieldDelegate

extension PopupCardView: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.memoTextView.isEditable = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        print(#function)
        self.updateTitleTextField()
    }
    
    
}


// MARK: - UITextViewDelegate

extension PopupCardView: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        print(#function)
        self.isTextViewChanged = true
        self.isEdited = true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        print(#function)
        self.updateMemoTextView()
    }
    
}


// MARK: - Initial UI Properties Settings

extension PopupCardView {
    
    private func setupTitleTextField() {
        let bar = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        let hideKeyboardButton = UIBarButtonItem(image: UIImage(systemName: "keyboard.chevron.compact.down"),
                                                 style: .plain,
                                                 target: self,
                                                 action: #selector(keyboardHideButtonTapped))
        let flexibleBarButton = UIBarButtonItem(systemItem: UIBarButtonItem.SystemItem.flexibleSpace)
        bar.items = [flexibleBarButton, hideKeyboardButton]
        bar.sizeToFit()
        bar.tintColor = .currentTheme
        titleTextField.inputAccessoryView = bar
        
        titleTextField.font = UIFont.systemFont(ofSize: 18)
        titleTextField.placeholder = "제목 없음".localized()
        titleTextField.borderStyle = .none
        titleTextField.text = ""
        titleTextField.textAlignment = .left
        titleTextField.backgroundColor = .clear
        titleTextField.textColor = UIColor.label
        titleTextField.tintColor = .currentTheme
        titleTextField.minimumFontSize = 16 //같은 셀의 textView의 폰트는 13.5 <- 이보다는 커야 한다.
        titleTextField.adjustsFontSizeToFitWidth = true
    }
    
    private func setupLikeButton() {
        likeButton.configuration?.image = .init(systemName: "heart")
        likeButton.configuration?.baseBackgroundColor = .clear
        likeButton.configuration?.baseForegroundColor = .systemRed
        likeButton.configurationUpdateHandler = { button in
            let imageName = button.isSelected ? "heart.fill" : "heart"
            button.configuration?.image = UIImage(systemName: imageName)
        }
    }
    
    private func setupEllipsisButton() {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "ellipsis.circle")
        configuration.title = ""
        configuration.contentInsets = .zero
        configuration.imagePlacement = .all
        configuration.background.backgroundColor = .clear
        ellipsisButton.configuration = configuration
        ellipsisButton.configurationUpdateHandler = { button in
            switch button.state {
            case .normal:
                button.configuration?.image = UIImage(systemName: "ellipsis.circle")
                button.tintColor = UIColor.currentTheme
            case .highlighted:

                button.tintColor = UIColor.currentTheme
            default:
                return
            }
        }
        ellipsisButton.showsMenuAsPrimaryAction = true
    }
    
    private func setupCategoryCollectionView() {
        categoryCollectionView.backgroundColor = .clear
        categoryCollectionView.register(
            TotalListCellCategoryCell.self,
            forCellWithReuseIdentifier: TotalListCellCategoryCell.cellID
        )
        categoryCollectionView.clipsToBounds = true
        categoryCollectionView.showsHorizontalScrollIndicator = false
        categoryCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    private func setupImageCollectionView() {
        imageCollectionView.register(
            MemoImageCollectionViewCell.self,
            forCellWithReuseIdentifier: MemoImageCollectionViewCell.cellID
        )
        imageCollectionView.isScrollEnabled = true
        imageCollectionView.backgroundColor = .clear
        imageCollectionView.showsHorizontalScrollIndicator = false
        imageCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        imageCollectionView.clipsToBounds = true
        imageCollectionView.layer.cornerRadius = 13
        imageCollectionView.layer.cornerCurve = .continuous
    }
    
    private func setupMemoTextView() {
        if #available(iOS 16.0, *) {
            // iOS 16.0 이후에서는 TextKit2 사용기 기본값이기 때문에,
            // TextKit1 사용으로 통일하기 위해 usingTextLayoutManager 매개변수에 false 할당.
            memoTextView = UITextView(usingTextLayoutManager: false)
        } else {
            memoTextView = UITextView()
        }
        
        let bar = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        let hideKeyboardButton = UIBarButtonItem(
            image: .init(systemName: "keyboard.chevron.compact.down"),
            style: .plain,
            target: self,
            action: #selector(keyboardHideButtonTapped)
        )
        let flexibleBarButton = UIBarButtonItem(systemItem: UIBarButtonItem.SystemItem.flexibleSpace)
        bar.items = [flexibleBarButton, hideKeyboardButton]
        bar.sizeToFit()
        bar.tintColor = .currentTheme
        memoTextView.inputAccessoryView = bar
        
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.lineSpacing = 5
        let attributes = [
            NSAttributedString.Key.paragraphStyle: mutableParagraphStyle,
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.label
        ]
        memoTextView.typingAttributes = attributes
        
        memoTextView.backgroundColor = .clear
        memoTextView.textInputView.backgroundColor = .clear
        memoTextView.bounces = true
        memoTextView.tintColor = .currentTheme
        memoTextView.isEditable = false
        memoTextView.isScrollEnabled = true
        memoTextView.dataDetectorTypes = .link
        memoTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
        memoTextView.textContainerInset  = .zero
        memoTextView.textContainer.lineFragmentPadding = 0
        memoTextView.clipsToBounds = true
        memoTextView.layer.cornerRadius = 25
        memoTextView.layer.cornerCurve = .continuous
        memoTextView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
    }
    
    private func setupMemoDateLabel() {
        memoDateLabel.text = "----.--.--.에 생성됨"
        memoDateLabel.textColor = .lightGray
        memoDateLabel.font = .systemFont(ofSize: 14)
        memoDateLabel.numberOfLines = 1
    }
    
}
