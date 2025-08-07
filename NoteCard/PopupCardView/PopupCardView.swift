//
//  PopupCardView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

final class PopupCardView: UIView {
    
    private let heartImageViewTapGesture = UITapGestureRecognizer()
    let memoTextViewTapGesture = UITapGestureRecognizer()
    private let screenSize = UIScreen.current?.bounds.size
    
    private var memoEntity: MemoEntity?
    
    weak var delegate: LargeCardCollectionViewCellDelegate?
    
    var sortedImageEntitiesArray: [ImageEntity] = []
    private var thumbnailArray: [UIImage] = []
    private var imageArray: [UIImage] = []
    var numberOfImages: Int = 0
    private var keyboardFrame: CGRect = .zero
    private var isViewShiftedUp: Bool = false
    private var isTextFieldChanged: Bool = false
    var isTextViewChanged: Bool = false
    var isEdited: Bool = false
    
//    private lazy var popupCardVerticalPadding
//    = (screenSize!.height - bounds.height) / 2
//    
//    lazy var titleTextFieldTopConstraint
//    = titleTextField.topAnchor.constraint(equalTo: topAnchor, constant: 15)
//    
//    lazy var selectedImageCollectionViewTopConstraint
//    = self.imageCollectionView.topAnchor.constraint(
//        equalTo: categoryCollectionView.bottomAnchor,
//        constant: 0
//    )
    lazy var selectedImageCollectionViewHeightConstraint
    = self.imageCollectionView.heightAnchor.constraint(equalToConstant: 0)
//    
//    lazy var titleTextFieldLeadingConstraint
//    = titleTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25)
//    
//    lazy var heartImageViewTopConstraint
//    = heartImageView.topAnchor.constraint(equalTo: topAnchor, constant: 14)
//    
//    lazy var heartImageViewLeadingConstraint
//    = heartImageView.leadingAnchor.constraint(equalTo: titleTextField.trailingAnchor, constant: 10)
//    
//    lazy var heartImageViewTrailingConstraint
//    = heartImageView.trailingAnchor.constraint(equalTo: ellipsisButton.leadingAnchor, constant: 0)
//    
//    lazy var heartImageViewTrailingToPopupCardViewConstraint
//    = self.heartImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
//    
//    lazy var heartImageViewWidthConstraint
//    = heartImageView.widthAnchor.constraint(equalToConstant: 27)
//    
//    lazy var heartImageViewHeightConstraint
//    = heartImageView.heightAnchor.constraint(equalToConstant: 27)
//    
//    lazy var memoTextViewLeadingConstraint
//    = memoTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10)
//    
//    lazy var memoTextViewTrailingConstraint
//    = memoTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
    
    var cellSnapshot: UIView!
    var popupCardSnapshot: UIView!
    
    let titleTextField = UITextField()
    let heartImageView = UIImageView(image: .init(systemName: "heart"))
    let ellipsisButton = UIButton()
    
    private let makeCategoryFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 10
        flowLayout.scrollDirection = .horizontal
        flowLayout.estimatedItemSize = CGSize(width: 50, height: 25)
        return flowLayout
    }
    lazy var categoryCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: makeCategoryFlowLayout()
    )
    
    private let makeImageFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 10
        flowLayout.sectionInset = .zero
        flowLayout.itemSize = CGSize(width: 70, height: 70)
        flowLayout.scrollDirection = .horizontal
        return flowLayout
    }
    lazy var imageCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: makeImageFlowLayout()
    )
    
    var memoTextView: UITextView!
    let memoDateLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        configureHierarchy()
        setupConstraints()
        setupGestures()
        setupActions()
        setupDelegates()
//        setupObserver()
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
        backgroundColor = UIColor.memoBackground
        layer.cornerCurve = .continuous
        
        setupTitleTextField()
        setupHeartImageView()
        setupEllipsisButton()
        setupCategoryCollectionView()
        setupImageCollectionView()
        setupMemoTextView()
        setupMemoDateLabel()
    }
    
    private func configureHierarchy() {
        addSubview(titleTextField)
        addSubview(heartImageView)
        addSubview(ellipsisButton)
        addSubview(categoryCollectionView)
        addSubview(imageCollectionView)
        addSubview(memoTextView)
        addSubview(memoDateLabel)
    }
    
    private func setupGestures() {
        self.heartImageView.addGestureRecognizer(self.heartImageViewTapGesture)
        self.heartImageViewTapGesture.addTarget(self, action: #selector(heartImageViewTapped))
        
        self.memoTextView.addGestureRecognizer(self.memoTextViewTapGesture)
        self.memoTextViewTapGesture.addTarget(self, action: #selector(memoTextViewTapped(_:)))
    }
    
    @objc private func heartImageViewTapped() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
        guard let memoEntity else { fatalError() }
        memoEntity.isFavorite.toggle()
        switch memoEntity.isFavorite {
        case true:
            self.heartImageView.image = UIImage(systemName: "heart.fill")
        case false:
            self.heartImageView.image = UIImage(systemName: "heart")
        }
        
        appDelegate.saveContext()
    }
    
    @objc private func memoTextViewTapped(_ gesture: UITapGestureRecognizer) {
        print(#function)
        let tappedPoint = gesture.location(in: memoTextView)
        let glyphIndex = memoTextView.layoutManager.glyphIndex(
            for: tappedPoint,
            in: memoTextView.textContainer
        )
        
        //Ensure the glyphIndex actually matches the point and isn't just the closest glyph to the point
        let glyphRect = memoTextView.layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: memoTextView.textContainer)
        
        if glyphIndex < memoTextView.textStorage.length,
           glyphRect.contains(tappedPoint),
           let linkURL = memoTextView.textStorage.attribute(
            NSAttributedString.Key.link,
            at: glyphIndex,
            effectiveRange: nil
           ) {
            //해당 링크를 이용해서 인터넷 열리게끔 설정
            print(type(of: linkURL))
            print(linkURL)
            guard let linkURL = linkURL as? URL else { return }
            UIApplication.shared.open(linkURL)
            
        } else {
            
            let characterIndex = memoTextView.layoutManager.characterIndex(
                for: tappedPoint,
                in: memoTextView.textContainer,
                fractionOfDistanceBetweenInsertionPoints: nil
            )
            
            let glyphRect = memoTextView.layoutManager.boundingRect(
                forGlyphRange: NSRange(location: glyphIndex, length: 1), in: self.memoTextView.textContainer
            )
            
            //아래와 같이 쓰면 안됨. boundingRect는 GlyphRange를 기반으로 한 Rect를 반환하기 때문에, characterIndex를 쓰는 건 옳지 않다!
            //(합자-ligature-를 쓸 경우 잘못된 결과가 나올 수 있음) -> 메모용 주석
            // let characterRect = self.memoTextView.layoutManager.boundingRect(forGlyphRange: NSRange(location: characterIndex, length: 1), in: self.memoTextView.textContainer)
//            print(characterRect, "<-characterRect")
//            print(characterIndex, "<-characterIndex")
            
            print("???")
            print(glyphRect, "<-glyphRect")
            print(glyphIndex, "<-glyphIndex")
            print(self.memoTextView.textStorage.length, "<-textStorage's length")
            
            switch self.memoTextView.isEditable {
            case true: return
            case false:
                let tappedPosition: UITextPosition?
                
                print(characterIndex < self.memoTextView.textStorage.length)
                print(glyphRect.contains(tappedPoint))
                
                if characterIndex < self.memoTextView.textStorage.length && glyphRect.contains(tappedPoint) {
                    tappedPosition = self.memoTextView.position(
                        from: self.memoTextView.beginningOfDocument,
                        offset: characterIndex
                    )
                    
                } else if characterIndex >= self.memoTextView.textStorage.length - 1 {
                    tappedPosition = self.memoTextView.endOfDocument
                    
                } else {
                    tappedPosition = self.memoTextView.position(
                        from: self.memoTextView.beginningOfDocument,
                        offset: glyphIndex
                    )
                    
                }
                
                guard let tappedPosition else { return }
                self.memoTextView.isEditable = true
                self.memoTextViewTapGesture.isEnabled = false
                self.memoTextView.selectedTextRange = self.memoTextView.textRange(
                    from: tappedPosition,
                    to: tappedPosition
                )
                self.memoTextView.becomeFirstResponder()
            }
        }
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
        self.categoryCollectionView.dataSource = self
        self.imageCollectionView.dataSource = self
        self.titleTextField.delegate = self
        self.memoTextView.delegate = self
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            titleTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25),
            titleTextField.heightAnchor.constraint(equalToConstant: 30),
        ])
        
        NSLayoutConstraint.activate([
            heartImageView.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            heartImageView.leadingAnchor.constraint(equalTo: titleTextField.trailingAnchor, constant: 10),
            heartImageView.trailingAnchor.constraint(equalTo: ellipsisButton.leadingAnchor, constant: 0),
            heartImageView.widthAnchor.constraint(equalToConstant: 27),
            heartImageView.heightAnchor.constraint(equalToConstant: 27),
        ])
        
        NSLayoutConstraint.activate([
            ellipsisButton.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            ellipsisButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            ellipsisButton.widthAnchor.constraint(equalToConstant: 30),
            ellipsisButton.heightAnchor.constraint(equalToConstant: 30),
        ])
        
        NSLayoutConstraint.activate([
            categoryCollectionView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 10),
            categoryCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            categoryCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 25),
        ])
        
        selectedImageCollectionViewHeightConstraint.priority = UILayoutPriority(751)
        NSLayoutConstraint.activate([
            imageCollectionView.topAnchor.constraint(
                equalTo: categoryCollectionView.bottomAnchor,
                constant: 0
            ),
            imageCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            imageCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            selectedImageCollectionViewHeightConstraint,
        ])
        
        NSLayoutConstraint.activate([
            memoTextView.topAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: 10),
            memoTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            memoTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            memoTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
//            memoTextView.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor, constant: -10),
        ])
        
        NSLayoutConstraint.activate([
            memoDateLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30),
            memoDateLabel.topAnchor.constraint(equalTo: bottomAnchor, constant: 10),
        ])
    }
    
//    private func setupObserver() {
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(keyboardWillShow(_:)),
//            name: UIResponder.keyboardWillShowNotification, object: nil
//        )
//        
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(keyboardWillHide),
//            name: UIResponder.keyboardWillHideNotification, object: nil
//        )
//    }
    
//    @objc private func keyboardWillShow(_ notification: Notification) {
//        guard let keyboardFrame =
//                notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
//        else { fatalError() }
//        self.keyboardFrame = keyboardFrame
//        if !self.isViewShiftedUp && self.memoTextView.isFirstResponder {
//            self.shiftUpView()
//        }
//    }
    
//    @objc private func keyboardWillHide() {
//        guard let memoEntity else { fatalError() }
//        if self.isViewShiftedUp {
//            self.shiftDownView()
//        }
//        
//        self.memoTextView.isEditable = false
//        self.memoTextViewTapGesture.isEnabled = true
//        
//        if self.isEdited {
//            if self.isTextFieldChanged {
//                self.updateTitleTextField()
//            }
//            if self.isTextViewChanged {
//                self.updateMemoTextView()
//            }
//            
//            memoEntity.modificationDate = Date()
//            self.configureView(with: memoEntity)
//            NotificationCenter.default.post(
//                name: NSNotification.Name("editingCompleteNotification"),
//                object: nil,
//                userInfo: ["memo": memoEntity]
//            )
//        }
//    }
    
//    private func shiftUpView() {
//        print(#function)
//        guard let screenSize else { fatalError() }
//        let aspectRatio = screenSize.height / screenSize.width
//        let lengthToShrink = self.keyboardFrame.height - self.popupCardVerticalPadding
//        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
//        animator.addAnimations { [weak self] in
//            guard let self else { fatalError() }
//            self.isViewShiftedUp = true
//            self.frame.size.height = screenSize.height - (self.popupCardVerticalPadding * 2) - lengthToShrink
//            
//            if numberOfImages != 0, aspectRatio < 2 {
//                self.selectedImageCollectionViewHeightConstraint.constant = 0
//                self.layoutIfNeeded()
//            }
//            
//        }
//        animator.startAnimation()
//    }
    
//    func shiftDownView() {
//        guard let screenSize else { fatalError() }
//        let aspectRatio = screenSize.height / screenSize.width
//        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
//        animator.addAnimations { [weak self] in
//            guard let self else { fatalError() }
//            self.isViewShiftedUp = false
//            self.frame.size.height = screenSize.height - (self.popupCardVerticalPadding * 2)
//            
//            if numberOfImages != 0, aspectRatio < 2 {
//                self.selectedImageCollectionViewHeightConstraint.constant = 70
//                self.layoutIfNeeded()
//            }
//        }
//        
//        animator.startAnimation()
//    }
    
    
    private func updateTitleTextField() {
        if self.isTextFieldChanged {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
            guard let text = self.titleTextField.text else { fatalError() }
            self.memoEntity?.memoTitle = text
            appDelegate.saveContext()
        }
    }
    
    
    func updateMemoTextView() {
        if self.isTextViewChanged {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
            self.memoEntity?.memoText = self.memoTextView.text
            appDelegate.saveContext()
        }
    }
    
    
    func configureView(with memo: MemoEntity) {
        guard let orderCriterion = UserDefaults.standard.string(forKey: UserDefaultsKeys.orderCriterion.rawValue) else { fatalError() }
        
        self.memoEntity = memo
        self.thumbnailArray = []
        //Localizing 필요함
        
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
            
            self.heartImageViewTapGesture.isEnabled = false
            self.heartImageView.tintColor = .lightGray
            self.titleTextField.isEnabled = false
            self.memoTextViewTapGesture.isEnabled = false
            self.memoTextView.isEditable = false
            self.memoTextView.isSelectable = false
            
        } else if orderCriterion == OrderCriterion.creationDate.rawValue {
            self.memoDateLabel.text = String(format: "%@에 생성됨".localized(), memo.getCreationDateInString())
        } else {
            self.memoDateLabel.text = String(format: "%@에 수정됨".localized(), memo.getModificationDateString())
        }
        
        self.titleTextField.text = memo.memoTitle
        
        if memo.isFavorite {
            self.heartImageView.image = UIImage(systemName: "heart.fill")
        }
        
        self.memoTextView.setLineSpace(with: memo.memoText, lineSpace: 5, font: UIFont.systemFont(ofSize: 15), textColor: .label)
        if UserDefaults.standard.object(forKey: "themeColor") as! String == ThemeColor.black.rawValue {
            self.memoTextView.linkTextAttributes =
            [NSAttributedString.Key.foregroundColor: UIColor.systemGray,
             NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]
        } else {
            self.memoTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.currentTheme]
        }
        
        self.sortedImageEntitiesArray = ImageEntityManager.shared.getImageEntities(from: self.memoEntity!, inOrderOf: ImageOrderIndexKind.orderIndex)
        
        self.numberOfImages = self.sortedImageEntitiesArray.count
        if numberOfImages == 0 {
            self.selectedImageCollectionViewHeightConstraint.constant = 0
        } else {
            self.selectedImageCollectionViewHeightConstraint.constant = 70
        }
        self.sortedImageEntitiesArray.forEach { [weak self] imageEntity in
            guard let self else { return }
            guard let thumbnail = ImageEntityManager.shared.getThumbnailImage(imageEntity: imageEntity) else { return }
            self.thumbnailArray.append(thumbnail)
        }
        self.imageArray = []
        
        //고화질 이미지를 가져오는 일은 오래 걸릴 수 있으므로 비동기적으로 구현.
        DispatchQueue.global().async {
            self.sortedImageEntitiesArray.forEach { [weak self] imageEntity in
                guard let self else { return }
                guard let image = ImageEntityManager.shared.getImage(imageEntity: imageEntity) else { return }
                self.imageArray.append(image)
            }
        }
        
        self.categoryCollectionView.reloadData()
        self.imageCollectionView.reloadData()
    }
    
    @objc private func keyboardHideButtonTapped() {
        self.endEditing(true)
    }
    
}


// MARK: - UICollectionViewDataSource

extension PopupCardView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.categoryCollectionView {
            let categoriesArray = CategoryEntityManager.shared.getCategoryEntities(memo: self.memoEntity, inOrderOf: CategoryProperties.modificationDate, isAscending: false)
            return categoriesArray.count
            
        } else {
            guard let memoEntity else { return 0 }
            let imageEntitiesArray = ImageEntityManager.shared.getImageEntities(from: memoEntity, inOrderOf: ImageOrderIndexKind.orderIndex)
            return imageEntitiesArray.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.categoryCollectionView {
            let categoriesArray = CategoryEntityManager.shared.getCategoryEntities(memo: self.memoEntity, inOrderOf: CategoryProperties.modificationDate, isAscending: false)
            let cell = self.categoryCollectionView.dequeueReusableCell(withReuseIdentifier: TotalListCellCategoryCell.cellID, for: indexPath) as! TotalListCellCategoryCell
            cell.categoryLabel.text = categoriesArray[indexPath.row].name
            return cell
            
        //if collectionView == self.selectedImageCollectionView
        } else {
            let cell = self.imageCollectionView.dequeueReusableCell(withReuseIdentifier: MemoImageCollectionViewCell.cellID, for: indexPath) as! MemoImageCollectionViewCell
            cell.imageView.image = self.thumbnailArray[indexPath.row]
            return cell
        }
    }
    
}


// MARK: - UITextFieldDelegate

extension PopupCardView: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.memoTextView.isEditable = false
        self.memoTextViewTapGesture.isEnabled = true
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
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupHeartImageView() {
        heartImageView.tintColor = .systemRed
        heartImageView.contentMode = .scaleAspectFit
        heartImageView.backgroundColor = .clear
        heartImageView.isUserInteractionEnabled = true
        heartImageView.translatesAutoresizingMaskIntoConstraints = false
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
                button.tintColor = .lightGray
            default:
                return
            }
        }
        
        ellipsisButton.translatesAutoresizingMaskIntoConstraints = false
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
        categoryCollectionView.translatesAutoresizingMaskIntoConstraints = false
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
        imageCollectionView.translatesAutoresizingMaskIntoConstraints = false
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
        memoTextView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupMemoDateLabel() {
        memoDateLabel.text = "----.--.--.에 생성됨"
        memoDateLabel.textColor = .lightGray
        memoDateLabel.font = .systemFont(ofSize: 14)
        memoDateLabel.numberOfLines = 1
        memoDateLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
}
