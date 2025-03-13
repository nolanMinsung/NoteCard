//
//  PopupCardView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

final class PopupCardView: UIView {
    
//    let CategoryEntityManager.shared = CategoryEntityManager.shared
//    let MemoEntityManager.shared = MemoEntityManager.shared
//    let ImageEntityManager.shared = ImageEntityManager.shared
    
//    let titleTextFieldTapGesture = UITapGestureRecognizer()
    let heartImageViewTapGesture = UITapGestureRecognizer()
    let memoTextViewTapGesture = UITapGestureRecognizer()
    let screenSize = UIScreen.current?.bounds.size
    
    var memoEntity: MemoEntity?
    
    weak var delegate: LargeCardCollectionViewCellDelegate?
    
    var sortedImageEntitiesArray: [ImageEntity] = []
    var thumbnailArray: [UIImage] = []
    var imageArray: [UIImage] = []
    var numberOfImages: Int = 0
    var keyboardFrame: CGRect = .zero
    var isViewShiftedUp: Bool = false
    var isTextFieldChanged: Bool = false
    var isTextViewChanged: Bool = false
    var isEdited: Bool = false
//    var categoryMayHaveChanged: Bool = false
    
    lazy var popupCardVerticalPadding = (screenSize!.height - self.bounds.height) / 2
    lazy var titleTextFieldTopConstraint = self.titleTextField.topAnchor.constraint(equalTo: self.topAnchor, constant: 15)
    lazy var selectedImageCollectionViewTopConstraint = self.selectedImageCollectionView.topAnchor.constraint(equalTo: self.selectedCategoryCollectionView.bottomAnchor, constant: 0)
    lazy var selectedImageCollectionViewHeightConstraint = self.selectedImageCollectionView.heightAnchor.constraint(equalToConstant: 0)
    lazy var titleTextFieldLeadingConstraint = self.titleTextField.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 25)
    
    lazy var heartImageViewTopConstraint = self.heartImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 14)
    lazy var heartImageViewLeadingConstraint = self.heartImageView.leadingAnchor.constraint(equalTo: self.titleTextField.trailingAnchor, constant: 10)
    lazy var heartImageViewTrailingConstraint = self.heartImageView.trailingAnchor.constraint(equalTo: self.ellipsisButton.leadingAnchor, constant: 0)
    lazy var heartImageViewTrailingToPopupCardViewConstraint = self.heartImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10)
    lazy var heartImageViewWidthConstraint = self.heartImageView.widthAnchor.constraint(equalToConstant: 27)
    lazy var heartImageViewHeightConstraint = self.heartImageView.heightAnchor.constraint(equalToConstant: 27)
    
    lazy var memoTextViewLeadingConstraint = self.memoTextView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10)
    lazy var memoTextViewTrailingConstraint = self.memoTextView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10)
    
    var cellSnapshot: UIView!
    var popupCardSnapshot: UIView!
    
    lazy var titleTextField: UITextField = { [weak self] in
        guard let self else { fatalError() }
        let textField = UITextField()
        
        let bar = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        let hideKeyboardButton = UIBarButtonItem(image: UIImage(systemName: "keyboard.chevron.compact.down"),
                                                 style: .plain,
                                                 target: self,
                                                 action: #selector(keyboardHideButtonTapped))
        let flexibleBarButton = UIBarButtonItem(systemItem: UIBarButtonItem.SystemItem.flexibleSpace)
        bar.items = [flexibleBarButton, hideKeyboardButton]
        bar.sizeToFit()
        bar.tintColor = .currentTheme()
        textField.inputAccessoryView = bar
        
        textField.font = UIFont.systemFont(ofSize: 18)
        textField.placeholder = "제목 없음".localized()
        textField.borderStyle = .none
        textField.text = ""
        textField.textAlignment = .left
        textField.backgroundColor = .clear
        textField.textColor = UIColor.label
        textField.tintColor = .currentTheme()
        textField.minimumFontSize = 16 //같은 셀의 textView의 폰트는 13.5 <- 이보다는 커야 한다.
        textField.adjustsFontSizeToFitWidth = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    
    let heartImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "heart")
        imageView.tintColor = .systemRed
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    
    
    /*
    lazy var restoreMemoAction = UIAction(
        title: "카테고리 없는 메모로 복구".localized(),
        image: UIImage(systemName: "tag.slash")?.withTintColor(.currentTheme(), renderingMode: UIImage.RenderingMode.alwaysOriginal),
        handler: { [weak self] action in
            guard let self else { fatalError() }
            guard let memoEntity else { fatalError() }
            guard let delegate else { fatalError() }
            
            self.endEditing(true)
            
            let alertCon = UIAlertController(title: "이 메모를 복구하시겠습니까?".localized(), message: "복구된 메모는 '카테고리 없음' 항목에서 확인할 수 있습니다.".localized(), preferredStyle: UIAlertController.Style.alert)
            let cancelAction = UIAlertAction(title: "취소".localized(), style: UIAlertAction.Style.cancel)
            let restoreAction = UIAlertAction(title: "복구".localized(), style: UIAlertAction.Style.default) { action in
                MemoEntityManager.shared.restoreFromTrash(memoEntity: memoEntity)
                delegate.triggerApplyingSnapshot(animatingDifferences: true, usingReloadData: false, completionForCompositional: nil, completionForFlow: nil)
                NotificationCenter.default.post(name: NSNotification.Name("memoRecoveredToUncategorizedNotification"), object: nil, userInfo: ["recoveredMemos": [memoEntity]])
            }
            alertCon.addAction(cancelAction)
            alertCon.addAction(restoreAction)
            
            
            
            delegate.triggerPresentMethod(presented: alertCon, animated: true)
        }
    )
    */
    
    
    /*
    lazy var presentEditingModeAction = UIAction(
        title: "편집 모드".localized(),
        image: UIImage(systemName: "pencil"),
        handler: { [weak self] action in
            guard let self else { return }
            guard let memoEntityToEdit = self.memoEntity else { return }
            guard let delegate = self.delegate else { return }
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
            
            self.endEditing(true)
            let memoEditingVC = MemoEditingViewController(memo: memoEntityToEdit)
            appDelegate.memoEditingVC = memoEditingVC
            let memoEditingNaviCon = UINavigationController(rootViewController: memoEditingVC)
            delegate.triggerPresentMethod(presented: memoEditingNaviCon, animated: true)
        }
    )
    */
    
    
    /*
    lazy var deleteMemoAction = UIAction(
        title: "이 메모 삭제하기".localized(),
        image: UIImage(systemName: "trash"),
        attributes: UIMenuElement.Attributes.destructive,
        handler: { [weak self] action in
            guard let self else { return }
            guard let memoEntityToDelete = self.memoEntity else { return }
            guard let delegate else { return }
            
            self.endEditing(true)
            let alertCon: UIAlertController
            if memoEntityToDelete.isInTrash {
                alertCon = UIAlertController(
                    title: "선택한 메모를 영구적으로 삭제하시겠습니까?".localized(),
                    message: "이 동작은 취소할 수 없습니다.".localized(),
                    preferredStyle: UIAlertController.Style.actionSheet
                )
            } else {
                alertCon = UIAlertController(title: "메모 삭제".localized(), message: "메모를 삭제하시겠습니까?".localized(), preferredStyle: UIAlertController.Style.alert)
            }
            alertCon.view.tintColor = .currentTheme()
            let cancelAction = UIAlertAction(title: "취소".localized(), style: .cancel)
            let deleteAction = UIAlertAction(title: "삭제".localized(), style: .destructive) { action in
                if memoEntityToDelete.isInTrash {
                    MemoEntityManager.shared.deleteMemoEntity(memoEntity: memoEntityToDelete)
                } else {
                    MemoEntityManager.shared.sendToTrash(memoEntity: memoEntityToDelete)
                }
                NotificationCenter.default.post(name: NSNotification.Name("memoTrashedNotification"), object: nil, userInfo: ["trashedMemos": [memoEntityToDelete]])
            }
            alertCon.addAction(cancelAction)
            alertCon.addAction(deleteAction)
            delegate.triggerPresentMethod(presented: alertCon, animated: true)
        }
    )
     */
    
    
    
    
    
    lazy var ellipsisButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "ellipsis.circle")
        configuration.title = ""
        configuration.contentInsets = .zero
        configuration.imagePlacement = .all
        configuration.background.backgroundColor = .clear

        let button = UIButton(configuration: configuration)
        
        button.configurationUpdateHandler = { button in
            switch button.state {
            case .normal:
                button.configuration?.image = UIImage(systemName: "ellipsis.circle")
                button.tintColor = UIColor.currentTheme()
            case .highlighted:
                button.tintColor = .lightGray
            default:
                return
            }
        }
        
//        let button = UIButton()
//        
//        button.setImage(UIImage(systemName: "ellipsis.circle"), for: UIControl.State.normal)
//        button.setImage(UIImage(systemName: "ellipsis.circle")?.withTintColor(.lightGray), for: UIControl.State.selected)
//        button.contentVerticalAlignment = .fill
//        button.contentHorizontalAlignment = .fill
        button.translatesAutoresizingMaskIntoConstraints = false
        button.showsMenuAsPrimaryAction = true
//        button.menu = UIMenu(children: [self.presentEditingModeAction, self.deleteMemoAction])
        
        return button
    }()
    
    
//    let heartImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.image = UIImage(systemName: "heart")
//        imageView.tintColor = .systemRed
//        imageView.alpha = 0
//        imageView.contentMode = .scaleAspectFit
//        imageView.isUserInteractionEnabled = true
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        return imageView
//    }()
    
    
    let selectedCategoryCollectionView: UICollectionView = {
        let flowLayout: UICollectionViewFlowLayout = {
            let layout = UICollectionViewFlowLayout()
            layout.minimumLineSpacing = 10
            layout.scrollDirection = .horizontal
            layout.estimatedItemSize = CGSize(width: 50, height: 25)
            return layout
        }()
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.register(TotalListCellCategoryCell.self, forCellWithReuseIdentifier: TotalListCellCategoryCell.cellID)
        collectionView.clipsToBounds = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    
    
    let selectedImageCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 10
        flowLayout.sectionInset = .zero
        flowLayout.itemSize = CGSize(width: 70, height: 70)
        flowLayout.scrollDirection = .horizontal
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.register(MemoImageCollectionViewCell.self, forCellWithReuseIdentifier: MemoImageCollectionViewCell.cellID)
        collectionView.isScrollEnabled = true
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.clipsToBounds = true
        collectionView.layer.cornerRadius = 13
        collectionView.layer.cornerCurve = .continuous
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    
    lazy var memoTextView: UITextView = { [weak self] in
        guard let self else { fatalError() }
        //https://stackoverflow.com/questions/74517550/siwiftui-uitextview-is-switching-to-textkit-1
        //이 텍스트뷰는 layoutManager를 사용하는 것으로 인식했기 때문에 TextKit1으로 사용한다.
        //만약 UITextView() 의 방식으로 텍스트뷰를 생성한다면
        //iOS16+ 에서는 default로 TextKit2를 사용하는 것으로 되어있는데, 앞서 언급한 것처럼 TextKit1을 사용해야 하기 때문에
        //이를 TextKit2에서 TextKit1으로 switch 한다고 경고문 뜰 것임.
//        let view = UITextView(usingTextLayoutManager: false)
//        let view = UITextView()
        
        var view: UITextView
        
        if #available(iOS 16.0, *) {
            view = UITextView(usingTextLayoutManager: false)
        } else {
            view = UITextView()
        }
        
        let bar = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        let hideKeyboardButton = UIBarButtonItem(image: UIImage(systemName: "keyboard.chevron.compact.down"), style: .plain, target: self, action: #selector(keyboardHideButtonTapped))
        let flexibleBarButton = UIBarButtonItem(systemItem: UIBarButtonItem.SystemItem.flexibleSpace)
        bar.items = [flexibleBarButton, hideKeyboardButton]
        bar.sizeToFit()
        bar.tintColor = .currentTheme()
        view.inputAccessoryView = bar
        
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.lineSpacing = 5
        let attributes = [
            NSAttributedString.Key.paragraphStyle: mutableParagraphStyle,
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.label
        ]
        view.typingAttributes = attributes
        
        view.backgroundColor = .clear
        view.textInputView.backgroundColor = .clear
        view.bounces = true
        view.tintColor = .currentTheme()
        view.isEditable = false
        view.isScrollEnabled = true
        view.dataDetectorTypes = .link
        view.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
        view.textContainerInset  = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        view.textContainer.lineFragmentPadding = 0
        view.clipsToBounds = true
        view.layer.cornerRadius = 25
        view.layer.cornerCurve = .continuous
        view.layer.maskedCorners = CACornerMask(arrayLiteral: .layerMaxXMaxYCorner, .layerMinXMaxYCorner)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    
    let memoDateLabel: UILabel = {
        let label = UILabel()
        label.text = "1998.12.22.에 생성됨"
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        configureHierarchy()
        setupConstraints()
        setupGestures()
        setupActions()
        setupDelegates()
        setupObserver()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.traitCollection.userInterfaceStyle == .dark {
            self.layer.shadowPath = nil
            self.layer.shadowColor = nil
            
        } else {
            let bezierPath = UIBezierPath(rect: self.bounds)
            self.layer.shadowPath = bezierPath.cgPath
            self.layer.shadowColor = UIColor.currentTheme().cgColor
            self.layer.shadowOffset = CGSize(width: 0, height: 0)
            self.layer.shadowOpacity = 0.25
            self.layer.shadowRadius = 60
            
        }
    }
    
    
    private func setupUI() {
        self.backgroundColor = UIColor.memoBackground
        self.layer.cornerRadius = 37
        self.layer.cornerCurve = .continuous
    }
    
    
    private func configureHierarchy() {
        self.addSubview(self.titleTextField)
        self.addSubview(self.heartImageView)
        self.addSubview(self.ellipsisButton)
        self.addSubview(self.selectedCategoryCollectionView)
        self.addSubview(self.selectedImageCollectionView)
        self.addSubview(self.memoTextView)
        self.addSubview(self.memoDateLabel)
    }
    
    private func setupGestures() {
        self.heartImageView.addGestureRecognizer(self.heartImageViewTapGesture)
        self.heartImageViewTapGesture.addTarget(self, action: #selector(heartImageViewTapped))
        
        self.memoTextView.addGestureRecognizer(self.memoTextViewTapGesture)
        self.memoTextViewTapGesture.addTarget(self, action: #selector(memoTextViewTapped(_:)))
    }
    
    @objc private func heartImageViewTapped() {
        
        let heartImageChangeAnimator = UIViewPropertyAnimator(duration: 0.2, dampingRatio: 1)
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
        let tappedPoint = gesture.location(in: self.memoTextView)
        let glyphIndex = self.memoTextView.layoutManager.glyphIndex(for: tappedPoint, in: self.memoTextView.textContainer)
        
        //Ensure the glyphIndex actually matches the point and isn't just the closest glyph to the point
        let glyphRect = self.memoTextView.layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: self.memoTextView.textContainer)
        
        if glyphIndex < self.memoTextView.textStorage.length,
           glyphRect.contains(tappedPoint),
           let linkURL = self.memoTextView.textStorage.attribute(NSAttributedString.Key.link, at: glyphIndex, effectiveRange: nil) {
            //해당 링크를 이용해서 인터넷 열리게끔 설정
            print(type(of: linkURL))
            print(linkURL)
            guard let linkURL = linkURL as? URL else { return }
            UIApplication.shared.open(linkURL)
            
        } else {
            
            let characterIndex = self.memoTextView.layoutManager.characterIndex(for: tappedPoint, in: self.memoTextView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            //            let characterIndex = self.memoTextView.layoutManager.glyphIndex(for: tappedPoint, in: self.memoTextView.textContainer)
            
            let glyphRect = self.memoTextView.layoutManager.boundingRect(
                forGlyphRange: NSRange(location: glyphIndex, length: 1), in: self.memoTextView.textContainer
            )
            
            //이거 필요없는 코드. boundingRect는 GlyphRange를 기반으로 한 Rect를 반환하기 때문에, characterIndex를 쓰는 건 옳지 않다!
            //(합자-ligature-를 쓸 경우 잘못된 결과가 나올 수 있음) -> 기억하라고 코드 남겨둠.
//            let characterRect = self.memoTextView.layoutManager.boundingRect(
//                forGlyphRange: NSRange(location: characterIndex, length: 1), in: self.memoTextView.textContainer
//            )
            print("???")
            print(glyphRect, "<-glyphRect")
//            print(characterRect, "<-characterRect")
            print(glyphIndex, "<-glyphIndex")
//            print(characterIndex, "<-characterIndex")
            print(self.memoTextView.textStorage.length, "<-textStorage's length")
            
            switch self.memoTextView.isEditable {
                
            case true:
                return
                
            case false:
//                if titleTextField.isFirstResponder {
//                    self.titleTextFieldTapGesture.isEnabled = true
//                }
                
                let tappedPosition: UITextPosition?
                
                print(characterIndex < self.memoTextView.textStorage.length)
                print(glyphRect.contains(tappedPoint))
                
                if characterIndex < self.memoTextView.textStorage.length && glyphRect.contains(tappedPoint) {
                    tappedPosition = self.memoTextView.position(from: self.memoTextView.beginningOfDocument, offset: characterIndex)
                    
                } else if characterIndex >= self.memoTextView.textStorage.length - 1 {
                    tappedPosition = self.memoTextView.endOfDocument
                    
                } else {
                    tappedPosition = self.memoTextView.position(from: self.memoTextView.beginningOfDocument, offset: glyphIndex)
                    
                }
                
                guard let tappedPosition else { return }
                self.memoTextView.isEditable = true
                self.memoTextViewTapGesture.isEnabled = false
                
                self.memoTextView.selectedTextRange = self.memoTextView.textRange(from: tappedPosition, to: tappedPosition)
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
        self.selectedCategoryCollectionView.dataSource = self
//        self.selectedCategoryCollectionView.delegate = self
        
        self.selectedImageCollectionView.dataSource = self
//        self.selectedImageCollectionView.delegate = self
        
        self.titleTextField.delegate = self
        self.memoTextView.delegate = self
    }
    
    
    private func setupConstraints() {
        self.titleTextFieldTopConstraint.isActive = true
        self.titleTextFieldLeadingConstraint.isActive = true
        self.titleTextField.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
//        self.heartImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 14).isActive = true
//        self.heartImageView.leadingAnchor.constraint(equalTo: self.memoTitleLabel.trailingAnchor, constant: 10).isActive = true
//        self.heartImageView.widthAnchor.constraint(equalToConstant: 27).isActive = true
//        self.heartImageView.heightAnchor.constraint(equalToConstant: 27).isActive = true
        
        self.heartImageViewTopConstraint.isActive = true
        self.heartImageViewLeadingConstraint.isActive = true
        self.heartImageViewTrailingConstraint.isActive = true
        self.heartImageViewWidthConstraint.isActive = true
        self.heartImageViewHeightConstraint.isActive = true
        
        self.ellipsisButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 14).isActive = true
//        self.ellipsisButton.leadingAnchor.constraint(equalTo: self.heartImageView.trailingAnchor, constant: 0).isActive = true
        self.ellipsisButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -14).isActive = true
        self.ellipsisButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        self.ellipsisButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        self.selectedCategoryCollectionView.topAnchor.constraint(equalTo: self.titleTextField.bottomAnchor, constant: 10).isActive = true
        self.selectedCategoryCollectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10).isActive = true
        self.selectedCategoryCollectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
        self.selectedCategoryCollectionView.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        self.selectedImageCollectionViewTopConstraint.isActive = true
//        self.selectedImageCollectionView.topAnchor.constraint(equalTo: self.selectedCategoryCollectionView.bottomAnchor, constant: 0).isActive = true
        self.selectedImageCollectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10).isActive = true
        self.selectedImageCollectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
        self.selectedImageCollectionViewHeightConstraint.priority = UILayoutPriority(751)
        self.selectedImageCollectionViewHeightConstraint.isActive = true
        
        self.memoTextView.topAnchor.constraint(equalTo: self.selectedImageCollectionView.bottomAnchor, constant: 10).isActive = true
        self.memoTextViewLeadingConstraint.isActive = true
        self.memoTextViewTrailingConstraint.isActive = true
//        self.memoTextView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10).isActive = true
//        self.memoTextView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
        self.memoTextView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
        
        self.memoDateLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -30).isActive = true
        self.memoDateLabel.topAnchor.constraint(equalTo: self.bottomAnchor, constant: 10).isActive = true
    }
    
    private func setupObserver() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        print(#function)
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { fatalError() }
        self.keyboardFrame = keyboardFrame
        if !self.isViewShiftedUp && self.memoTextView.isFirstResponder {
            self.shiftUpView()
        }
    }
    
    @objc private func keyboardWillHide() {
        guard let memoEntity else { fatalError() }
        if self.isViewShiftedUp {
            self.shiftDownView()
        }
        
//        if self.titleTextField.isFirstResponder {
//            self.titleTextFieldTapGesture.isEnabled = true
//            
//        } else if self.memoTextView.isFirstResponder {
//            self.memoTextView.resignFirstResponder()
//            self.updateMemoTextView()
//            self.memoTextView.isEditable = false
//            self.memoTextViewTapGesture.isEnabled = true
//        }
        
        self.memoTextView.isEditable = false
        self.memoTextViewTapGesture.isEnabled = true
        
        if self.isEdited {
            
            if self.isTextFieldChanged {
                self.updateTitleTextField()
            }
            if self.isTextViewChanged {
                self.updateMemoTextView()
            }
            
            memoEntity.modificationDate = Date()
            self.configureView(with: memoEntity)
            NotificationCenter.default.post(name: NSNotification.Name("editingCompleteNotification"), object: nil, userInfo: ["memo": memoEntity])
        }
    }
    
    @objc private func keyboardDidHide() {
        
        
        
    }
    
    
    
    private func shiftUpView() {
        print(#function)
        guard let screenSize else { fatalError() }
        let aspectRatio = screenSize.height / screenSize.width
        let lengthToShrink = self.keyboardFrame.height - self.popupCardVerticalPadding
        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
        animator.addAnimations { [weak self] in
            guard let self else { fatalError() }
            self.isViewShiftedUp = true
            self.frame.size.height = screenSize.height - (self.popupCardVerticalPadding * 2) - lengthToShrink
            
            if numberOfImages != 0, aspectRatio < 2 {
//            if let themeColor = UserDefaults.standard.value(forKey: KeysForUserDefaults.themeColor.rawValue) as? String, themeColor == ThemeColor.blue.rawValue {
                self.selectedImageCollectionViewHeightConstraint.constant = 0
                self.layoutIfNeeded()
            }
            
        }
//        animator.addCompletion { _ in
//            self.isViewShiftedUp = true
//        }
        animator.startAnimation()
    }
    
    func shiftDownView() {
        guard let screenSize else { fatalError() }
//        let lengthToExpand = self.keyboardFrame.height - self.popupCardVerticalPadding
        let aspectRatio = screenSize.height / screenSize.width
        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
        animator.addAnimations { [weak self] in
            guard let self else { fatalError() }
            self.isViewShiftedUp = false
            self.frame.size.height = screenSize.height - (self.popupCardVerticalPadding * 2)
            
            if numberOfImages != 0, aspectRatio < 2 {
//            if let themeColor = UserDefaults.standard.value(forKey: KeysForUserDefaults.themeColor.rawValue) as? String, themeColor == ThemeColor.blue.rawValue {
                self.selectedImageCollectionViewHeightConstraint.constant = 70
                self.layoutIfNeeded()
            }
        }
        
        animator.startAnimation()
    }
    
    
    private func updateTitleTextField() {
        if self.isTextFieldChanged {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
            guard let text = self.titleTextField.text else { fatalError() }
            self.memoEntity?.memoTitle = text
//            self.memoEntity?.modificationDate = Date()
            appDelegate.saveContext()
        }
    }
    
    
    func updateMemoTextView() {
        if self.isTextViewChanged {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
            self.memoEntity?.memoText = self.memoTextView.text
//            self.memoEntity?.modificationDate = Date()
            appDelegate.saveContext()
        }
    }
    
    
//    func updateTexts() {
//        guard let memoEntity else { fatalError() }
//        switch (self.isTextFieldChanged, self.isTextViewChanged) {
//        case (true, true):
//            self.updateTitleTextField()
//            self.updateMemoTextView()
//            print("post함")
//            NotificationCenter.default.post(name: NSNotification.Name("editingCompleteNotification"), object: nil, userInfo: ["memo": memoEntity])
//            print("post함")
//        case (true, false):
//            self.updateTitleTextField()
//            NotificationCenter.default.post(name: NSNotification.Name("editingCompleteNotification"), object: nil, userInfo: ["memo": memoEntity])
//        case (false, true):
//            self.updateMemoTextView()
//            NotificationCenter.default.post(name: NSNotification.Name("editingCompleteNotification"), object: nil, userInfo: ["memo": memoEntity])
//        case (false, false):
//            return
//        }
//    }
    
    
    func configureView(with memo: MemoEntity) {
        guard let orderCriterion = UserDefaults.standard.string(forKey: KeysForUserDefaults.orderCriterion.rawValue) else { fatalError() }
        
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
            
//            self.ellipsisButton.menu = UIMenu(children: [self.restoreMemoAction, self.deleteMemoAction])
        } else if orderCriterion == OrderCriterion.creationDate.rawValue {
            self.memoDateLabel.text = String(format: "%@에 생성됨".localized(), memo.getCreationDateInString())
//            self.ellipsisButton.menu = UIMenu(children: [self.presentEditingModeAction, self.deleteMemoAction])
        } else {
            self.memoDateLabel.text = String(format: "%@에 수정됨".localized(), memo.getModificationDateString())
//            self.ellipsisButton.menu = UIMenu(children: [self.presentEditingModeAction, self.deleteMemoAction])
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
            self.memoTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.currentTheme()]
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
            
//            DispatchQueue.global().async { [weak self] in
//                guard let self else { return }
////                guard let image = ImageEntityManager.shared.getImage(memoEntity: memoEntity, uuid: imageEntity.uuid) else { return }
//                guard let image = ImageEntityManager.shared.getImage(imageEntity: imageEntity) else { fatalError() }
//                //MARK: imageArray에 append를 비동기적으로 하면 순서가 뒤바뀐다!!
//                self.imageArray.append(image)
//            }
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
        
        self.selectedCategoryCollectionView.reloadData()
        self.selectedImageCollectionView.reloadData()
    }
    
    @objc private func keyboardHideButtonTapped() {
        self.endEditing(true)
    }
    
    
}




extension PopupCardView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.selectedCategoryCollectionView {
            let categoriesArray = CategoryEntityManager.shared.getCategoryEntities(memo: self.memoEntity, inOrderOf: CategoryProperties.modificationDate, isAscending: false)
            return categoriesArray.count
            
        } else {
            guard let memoEntity else { return 0 }
            let imageEntitiesArray = ImageEntityManager.shared.getImageEntities(from: memoEntity, inOrderOf: ImageOrderIndexKind.orderIndex)
            return imageEntitiesArray.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == self.selectedCategoryCollectionView {
            let categoriesArray = CategoryEntityManager.shared.getCategoryEntities(memo: self.memoEntity, inOrderOf: CategoryProperties.modificationDate, isAscending: false)
            let cell = self.selectedCategoryCollectionView.dequeueReusableCell(withReuseIdentifier: TotalListCellCategoryCell.cellID, for: indexPath) as! TotalListCellCategoryCell
            cell.categoryLabel.text = categoriesArray[indexPath.row].name
            return cell
            
        //if collectionView == self.selectedImageCollectionView
        } else {
            let cell = self.selectedImageCollectionView.dequeueReusableCell(withReuseIdentifier: MemoImageCollectionViewCell.cellID, for: indexPath) as! MemoImageCollectionViewCell
            cell.imageView.image = self.thumbnailArray[indexPath.row]
            return cell
        }
        
    }
    
}


//extension PopupCardView: UICollectionViewDelegate {
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        guard let delegate else { fatalError() }
//        guard collectionView == self.selectedImageCollectionView else { return }
//        delegate.triggerPresentMethod(selectedItemAt: indexPath, imageArray: self.imageArray)
//    }
//    
//}


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


extension PopupCardView: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        print(#function)
        self.isTextViewChanged = true
        self.isEdited = true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return true
    }
    
    //이상하다...textViewDidEndEditing이 textField로 firstResponder가 바뀔 때만 호출된다...키보드가 내려가도 호출되지 않음...
    //왠진 모르겠는데, keyboardWillHide notification의 observer로 self 를 등록하면 textViewDidEndEditing이 호출되지 않는다.
    //그래서 일단 textViewDidEndEditing 에서 호출해야 하는 updateMemoTextView() 메서드를 keyboardWillHide() 메서드에서 호출했음.
    //근데 웃긴건 MemoDetailView에서도 keyboardWillHide() 옵저버 등록했는데 걔는 또 textViewDidEndEditing 이 잘 불린다.
    //아마 Notification하고 Observer들끼리 복잡하게 연결되면서 서로 꼬인 것 같음...
    func textViewDidEndEditing(_ textView: UITextView) {
        print(#function)
        self.updateMemoTextView()
    }
    
    
//    func textViewDidChangeSelection(_ textView: UITextView) {
//        print(#function)
//        
//        if self.isViewShiftedUp {
//            return
//        } else {
//            textView.resignFirstResponder()
//        }
//    }
    
}
