//
//  CardCompositionalCollectionViewCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit


//셀 안의 셀을 선택했을 때 present하는 게 목적.
//present 하면서 원본 image를 띄워야 하는데 셀의 선택을 감지하는 것은 cell 객체이므로 view controller로 원본 image 정보를 건네줘야한다.
//(present 메서드는  view controller에서 호출해야 한다.)
//-> 델리게이트패턴 사용

/// CardCompositionalCollectionViewCell 안의 사진을 터치했을 때, 사진을 보여주는 새로운 view controller를 present하는 메서드를 사용해야 한다.
/// present 메서드는 UIViewController의 인스턴스 메서드이므로 view controller에서 호출할 수 있게, delegate 패턴으로 넘겨주기 위한 프로토콜
protocol LargeCardCollectionViewCellDelegate: AnyObject {
    
    
    /// 셀이 select되면 호출되는 메서드.
    /// - Parameters:
    ///   - indexPath: select된 cell의 indexPath
    ///   - imageArray: present할 view controller에 넘겨줄 [UIImage] 타입의 배열
    func triggerPresentMethod(selectedItemAt indexPath: IndexPath, imageEntitiesArray: [ImageEntity])
    
    func triggerPresentMethod(presented presentedVC: UIViewController, animated: Bool)
    
    func triggerApplyingSnapshot(animatingDifferences: Bool, usingReloadData: Bool, completionForCompositional: (() -> Void)?, completionForFlow: (() -> Void)?)
    
    func updateDataSource()
}


class LargeCardCollectionViewCell: UICollectionViewCell {
    
    
    static var cellID: String {
        return String(describing: self)
    }
    
    let categoryEntityManager = CategoryEntityManager.shared
    let memoEntityManager = MemoEntityManager.shared
    let imageEntityManager = ImageEntityManager.shared
    let titleTextFieldTapGesture = UITapGestureRecognizer()
    let heartImageViewTapGesture = UITapGestureRecognizer()
    let memoTextViewTapGesture = UITapGestureRecognizer()
    var collectionViewHeight: CGFloat = 0
    var cellLowerPadding: CGFloat = 0
    
    weak var delegate: LargeCardCollectionViewCellDelegate?
    
    var sortedImageEntityArray: [ImageEntity] = []
    var thumbnailArray: [UIImage] = []
    var imageArray: [UIImage] = []
    var memoEntity: MemoEntity?
    var keyboardFrame: CGRect = .zero
    var isCellShiftedUp: Bool = false
    var isEdited: Bool = false
    var isTextFieldChanged: Bool = false
    var isTextViewChanged: Bool = false
    
//    lazy var cellHeightConstraint = self.heightAnchor.constraint(equalToConstant: 0)
    lazy var selectedImageCollectionViewHeightConstraint = self.selectedImageCollectionView.heightAnchor.constraint(equalToConstant: 0)
    
    
    let memoDateLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
//    var labelTitle: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 20)
//        label.textAlignment = .left
//        label.backgroundColor = .clear
//        label.textColor = UIColor.label
//        label.numberOfLines = 1
//        label.adjustsFontSizeToFitWidth = true
//        label.minimumScaleFactor = 0.8
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
    
    lazy var titleTextField: UITextField = { [weak self] in
        guard let self else { fatalError() }
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.placeholder = "제목 없음".localized()
        textField.borderStyle = .none
        textField.text = ""
        textField.textAlignment = .left
        textField.backgroundColor = .clear
        textField.textColor = UIColor.label
        textField.tintColor = .currentTheme()
        textField.minimumFontSize = 16 //같은 셀의 textView의 폰트는 15 <- 이보다는 커야 한다.
        textField.adjustsFontSizeToFitWidth = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        let bar = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        let hideKeyboardButton = UIBarButtonItem(image: UIImage(systemName: "keyboard.chevron.compact.down"), style: .plain, target: self, action: #selector(keyboardHideButtonTapped))
        let flexibleBarButton = UIBarButtonItem(systemItem: UIBarButtonItem.SystemItem.flexibleSpace)
        bar.items = [flexibleBarButton, hideKeyboardButton]
        bar.sizeToFit()
        bar.tintColor = .currentTheme()
        textField.inputAccessoryView = bar
        
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
    
    
    lazy var addCategoryAction = UIAction(
        title: memoEntity?.isInTrash == true ? "복구할 카테고리 선택".localized() : "카테고리 일괄 추가".localized(),
        image: UIImage(systemName: "tag")?.withTintColor(.currentTheme(), renderingMode: UIImage.RenderingMode.alwaysOriginal),
        handler: { [weak self] action in
            guard let self else { fatalError() }
            guard let delegate else { fatalError() }
            guard let memoEntity else { fatalError() }
            
            let categorySelectionVC = CategorySelectionViewController(selectionType: .toAppend)
            let naviCon = UINavigationController(rootViewController: categorySelectionVC)
            
            naviCon.modalPresentationStyle = .pageSheet
            delegate.triggerPresentMethod(presented: naviCon, animated: true)
        }
    )
    
    
    
    lazy var restoreMemoAction = UIAction(
        title: "카테고리 없는 메모로 복구".localized(),
        image: UIImage(systemName: "arrow.counterclockwise")?.withTintColor(.currentTheme(), renderingMode: UIImage.RenderingMode.alwaysOriginal),
        handler: { [weak self] action in
            guard let self else { fatalError() }
            guard let memoEntity else { fatalError() }
            guard let delegate else { fatalError() }
            
            self.endEditing(true)
            
            let alertCon = UIAlertController(title: "이 메모를 복구하시겠습니까?".localized(), message: "복구된 메모는 '카테고리 없음' 항목에서 확인할 수 있습니다.".localized(), preferredStyle: UIAlertController.Style.alert)
            let cancelAction = UIAlertAction(title: "취소".localized(), style: UIAlertAction.Style.cancel)
            let restoreAction = UIAlertAction(title: "복구".localized(), style: UIAlertAction.Style.default) { [weak self] action in
                guard let self else { fatalError() }
                MemoEntityManager.shared.restoreMemo(memoEntity)
                NotificationCenter.default.post(name: NSNotification.Name("memoRecoveredToUncategorizedNotification"), object: nil, userInfo: ["recoveredMemos": [memoEntity]])
                
                guard let largeCardCollectionView = self.superview as? UICollectionView else { fatalError() }
                guard let indexPathToRestore = largeCardCollectionView.indexPath(for: self) else { fatalError() }
                self.delegate?.updateDataSource()
                largeCardCollectionView.deleteItems(at: [indexPathToRestore])
                
//                delegate.triggerApplyingSnapshot(animatingDifferences: true, usingReloadData: false, completionForCompositional: nil, completionForFlow: nil)
            }
            alertCon.addAction(cancelAction)
            alertCon.addAction(restoreAction)
            delegate.triggerPresentMethod(presented: alertCon, animated: true)
            
        }
    )
    
    
    lazy var presentEditingModeAction = UIAction(title: "편집 모드".localized(), image: UIImage(systemName: "pencil"), handler: { [weak self] action in
        guard let self else { return }
        guard let memoEntityToEdit = self.memoEntity else { return }
        guard let delegate else { return }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
        
        let memoEditingVC = MemoEditingViewController(memo: memoEntityToEdit)
        appDelegate.memoEditingVC = memoEditingVC
        let memoEditingNaviCon = UINavigationController(rootViewController: memoEditingVC)
        self.endEditing(true)
        delegate.triggerPresentMethod(presented: memoEditingNaviCon, animated: true)
    })
    
    
    lazy var deleteMemoAction = UIAction(title: "이 메모 삭제하기".localized(), image: UIImage(systemName: "trash"), attributes: UIMenuElement.Attributes.destructive, handler: { [weak self] action in
        guard let self else { fatalError() }
        guard let memoEntityToDelete = self.memoEntity else { fatalError() }
        guard let delegate else { fatalError() }
        self.endEditing(true)
        let alertCon: UIAlertController
        if memoEntityToDelete.isInTrash {
            alertCon = UIAlertController(title: "선택한 메모를 영구적으로 삭제하시겠습니까?".localized(), message: "이 동작은 취소할 수 없습니다.".localized(), preferredStyle: UIAlertController.Style.actionSheet)
        } else {
            alertCon = UIAlertController(title: "메모 삭제".localized(), message: "메모를 삭제하시겠습니까?".localized(), preferredStyle: UIAlertController.Style.alert)
        }
        alertCon.view.tintColor = .currentTheme()
        let cancelAction = UIAlertAction(title: "취소".localized(), style: .cancel)
        let deleteAction = UIAlertAction(title: "삭제".localized(), style: .destructive) { [weak self] action in
            guard let self else { return }
            if memoEntityToDelete.isInTrash {
                MemoEntityManager.shared.deleteMemoEntity(memoEntity: memoEntityToDelete)
            } else {
                MemoEntityManager.shared.trashMemo(memoEntityToDelete)
                NotificationCenter.default.post(name: NSNotification.Name("memoTrashedNotification"), object: nil, userInfo: ["trashedMemos": [memoEntityToDelete]])
            }
            
            guard let largeCardCollectionView = self.superview as? UICollectionView else { fatalError() }
            guard let indexPathToDelete = largeCardCollectionView.indexPath(for: self) else { fatalError() }
            self.delegate?.updateDataSource()
            largeCardCollectionView.deleteItems(at: [indexPathToDelete])
            
            delegate.triggerApplyingSnapshot(animatingDifferences: true, usingReloadData: false, completionForCompositional: nil, completionForFlow: nil)
        }
        alertCon.addAction(cancelAction)
        alertCon.addAction(deleteAction)
        delegate.triggerPresentMethod(presented: alertCon, animated: true)
        
    })
    
    
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
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.showsMenuAsPrimaryAction = true
//        button.menu = UIMenu(children: [self.addCategoryAction, self.presentEditingModeAction, self.deleteMemoAction])
        
        return button
    }()
    
    
    let compositionaLayoutForCategory: UICollectionViewCompositionalLayout = {
        
        //imageSection
        let categoryItemSize = NSCollectionLayoutSize(widthDimension: .estimated(50), heightDimension: .estimated(25))
        let categoryItem = NSCollectionLayoutItem(layoutSize: categoryItemSize)
        
        let categoryGroupSize = NSCollectionLayoutSize(widthDimension: .estimated(50), heightDimension: .estimated(25))
        let categoryGroup = NSCollectionLayoutGroup.vertical(layoutSize: categoryGroupSize, subitems: [categoryItem])
        
        let categorySection = NSCollectionLayoutSection(group: categoryGroup)
        categorySection.orthogonalScrollingBehavior = .continuous
        categorySection.interGroupSpacing = 5
        categorySection.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.scrollDirection = .vertical //default value
        
        let compositionalLayout = UICollectionViewCompositionalLayout(section: categorySection, configuration: configuration)
        
        return compositionalLayout
    }()
    
    
    lazy var selectedCategoryCollectionView: UICollectionView = { [weak self] in
        guard let self else { fatalError() }
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.compositionaLayoutForCategory)
        collectionView.register(TotalListCellCategoryCell.self, forCellWithReuseIdentifier: TotalListCellCategoryCell.cellID)
        collectionView.clipsToBounds = true
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = true
        collectionView.contentInset = .zero
        collectionView.isScrollEnabled = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    
    let compositionaLayoutForImage: UICollectionViewCompositionalLayout = {
        
        //imageSection
        let imageItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let imageItem = NSCollectionLayoutItem(layoutSize: imageItemSize)
        
        let imageGroupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(SizeContainer.compositionalCardThumbnailSize.width),
            heightDimension: .absolute(SizeContainer.compositionalCardThumbnailSize.height)
        )
        let imageGroup = NSCollectionLayoutGroup.vertical(layoutSize: imageGroupSize, subitems: [imageItem])
        let imageSection = NSCollectionLayoutSection(group: imageGroup)
        imageSection.orthogonalScrollingBehavior = .continuous
        imageSection.interGroupSpacing = 5
        imageSection.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.scrollDirection = .vertical //default value
        
        let compositionalLayout = UICollectionViewCompositionalLayout(section: imageSection, configuration: configuration)
        
        return compositionalLayout
    }()
    
    lazy var selectedImageCollectionView: UICollectionView = { [weak self] in
        guard let self else { return UICollectionView() }
        //compositional Layout 의 셀 안에 flowLayout을 넣으면 이상하게 튕기는 버그가 존재 (Card 자체가 Compositional Layout을 레이아웃으로 가진 컬렉션뷰의 셀이다.)
        //그래서 카드 안의 이미지는 가로 스크롤이 전부임에도 불구하고 compositional Layout으로 배치
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.compositionaLayoutForImage)
        collectionView.backgroundColor = .clear
        collectionView.register(MemoImageCollectionViewCell.self, forCellWithReuseIdentifier: MemoImageCollectionViewCell.cellID)
        collectionView.isScrollEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.bounces = false
        collectionView.clipsToBounds = true
        collectionView.layer.cornerRadius = 13
//        collectionView.layer.maskedCorners = CACornerMask(arrayLiteral: .layerMinXMaxYCorner, .layerMaxXMaxYCorner)
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
        let hideKeyboardButton = UIBarButtonItem(
            image: UIImage(systemName: "keyboard.chevron.compact.down"),
            style: .plain,
            target: self,
            action: #selector(keyboardHideButtonTapped))
        let flexibleBarButton = UIBarButtonItem(systemItem: UIBarButtonItem.SystemItem.flexibleSpace)
        bar.items = [flexibleBarButton, hideKeyboardButton]
        bar.sizeToFit()
        bar.tintColor = .currentTheme()
        view.inputAccessoryView = bar
        
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
        view.typingAttributes = attributes
        
        view.backgroundColor = .clear
        view.inputView?.backgroundColor = .clear
        view.bounces = true
        view.tintColor = .currentTheme()
        view.isEditable = false
        view.isScrollEnabled = true
        view.dataDetectorTypes = .link
        view.isUserInteractionEnabled = true
        view.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
        view.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        view.textContainer.lineFragmentPadding = 0
        view.clipsToBounds = true
        view.layer.cornerRadius = 23
        view.layer.cornerCurve = .continuous
        view.layer.maskedCorners = CACornerMask(arrayLiteral: .layerMaxXMaxYCorner, .layerMinXMaxYCorner)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    
    lazy var contentViewHeightConstraint = self.contentView.heightAnchor.constraint(equalToConstant: SizeContainer.screenSize.height * 0.6)
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        configureHierarchy()
        setupActions()
        setupGestures()
        setupDelegates()
        setConstraints()
        setupObserver()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
//    deinit {
//        print(#function)
//        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
//    }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.contentView.traitCollection.userInterfaceStyle == .dark {
            self.layer.shadowPath = nil
            self.layer.shadowColor = nil
            
        } else {
            let bezierPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 33)
            self.layer.shadowPath = bezierPath.cgPath
            self.layer.shadowColor = UIColor.currentTheme().cgColor
            self.layer.shadowOpacity = 0.5
            self.layer.shadowOffset = CGSize(width: 0, height: 0)
            self.layer.shadowRadius = 5
            
        }
    }
    
    
    
//    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        return super.hitTest(point, with: event)
//    }
    
    
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        self.endEditing(true)
//    }
    
    
//    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
//        print(#function)
//        return super.point(inside: point, with: event)
//    }
    
    
    private func setupUI() {
        //cell의 contentView의 layer가 아니라 cell의 layer 에 cornerRadius를 넣어주는 이유는
        //날짜를 표기하는 라벨을 셀 바깥에 표기해야 하는데, 이때 contentView의 clipsToBound = true로 설정되면
        //해당 라벨이 보이지 않을 것이기 때문...
        self.contentView.backgroundColor = UIColor.memoBackground
//        self.contentView.clipsToBounds = true
        self.contentView.layer.cornerRadius = 35
        self.contentView.layer.cornerCurve = .continuous
    }
    
    
    private func configureHierarchy() {
        self.contentView.addSubview(self.memoDateLabel)
        self.contentView.addSubview(self.titleTextField)
        self.contentView.addSubview(self.ellipsisButton)
        self.contentView.addSubview(self.selectedCategoryCollectionView)
        self.contentView.addSubview(self.selectedImageCollectionView)
        self.contentView.addSubview(self.memoTextView)
        self.contentView.addSubview(self.heartImageView)
    }
    
    private func setupActions() {
        self.titleTextField.addTarget(self, action: #selector(textFieldDidChagne(_:)), for: UIControl.Event.editingChanged)
    }
    
    @objc private func textFieldDidChagne(_ textField: UITextField) {
        self.isTextFieldChanged = true
        self.isEdited = true
    }
    
    private func setupGestures() {
//        self.titleTextField.addGestureRecognizer(self.titleTextFieldTapGesture)
//        self.titleTextFieldTapGesture.addTarget(self, action: #selector(titleTextFieldTapped))
        
        self.heartImageView.addGestureRecognizer(self.heartImageViewTapGesture)
        self.heartImageViewTapGesture.addTarget(self, action: #selector(heartImageViewTapped))
        
        self.memoTextView.addGestureRecognizer(self.memoTextViewTapGesture)
        self.memoTextViewTapGesture.addTarget(self, action: #selector(memoTextViewTapped(_:)))
        
    }
    
//    @objc private func titleTextFieldTapped() {
//        print(#function)
//        self.titleTextFieldTapGesture.isEnabled = false
//        if memoTextView.isFirstResponder {
//            self.shiftDownCell()
//            self.memoTextView.isEditable = false
////            self.memoTextViewTapGesture.isEnabled = true
//            self.updateMemoTextView()
//        }
//        self.panGesture.isEnabled = true
////        self.titleTextFieldTapGesture.isEnabled = false
//    }
    
    
    
    @objc private func heartImageViewTapped() {
        
        let heartImageChangeAnimator = UIViewPropertyAnimator(duration: 0.2, dampingRatio: 1)
        
        guard let memoEntity else { fatalError() }
        memoEntity.isFavorite.toggle()
        switch memoEntity.isFavorite {
        case true:
            heartImageChangeAnimator.addAnimations { [weak self] in
                guard let self else { return }
                self.heartImageView.image = UIImage(systemName: "heart.fill")
            }
            
        case false:
            heartImageChangeAnimator.addAnimations { [weak self] in
                guard let self else { return }
                self.heartImageView.image = UIImage(systemName: "heart")
            }
        }
        heartImageChangeAnimator.startAnimation()
    }
    
    
    @objc private func memoTextViewTapped(_ gesture: UITapGestureRecognizer) {
        
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
            
            let characterIndex = self.memoTextView.layoutManager.characterIndex(for: tappedPoint, in: self.memoTextView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil
            )
            //            let characterIndex = self.memoTextView.layoutManager.glyphIndex(for: tappedPoint, in: self.memoTextView.textContainer)
            
            let glyphRect = self.memoTextView.layoutManager.boundingRect(
                forGlyphRange: NSRange(location: glyphIndex, length: 1), in: self.memoTextView.textContainer
            )
            
            //아래 characterRect- 는 필요없는 코드. boundingRect는 GlyphRange를 기반으로 한 Rect를 반환하기 때문에, characterIndex를 쓰는 건 옳지 않다!
            //(합자-ligature-를 쓸 경우 잘못된 결과가 나올 수 있음) -> 기억하라고 코드 남겨둠.
            //let characterRect = self.memoTextView.layoutManager.boundingRect(
            //    forGlyphRange: NSRange(location: characterIndex, length: 1), in: self.memoTextView.textContainer
            //)
            
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
                } else if characterIndex < self.memoTextView.textStorage.length && !glyphRect.contains(tappedPoint) {
                    tappedPosition = self.memoTextView.position(from: self.memoTextView.beginningOfDocument, offset: characterIndex)
                } else {
//                    tappedPosition = self.memoTextView.position(from: self.memoTextView.beginningOfDocument, offset: glyphIndex + 1)
                    tappedPosition = self.memoTextView.endOfDocument
//                    return
                }
                //guard let tappedPosition = self.memoTextView.position(from: self.memoTextView.beginningOfDocument, offset: glyphIndex) else { return }
                
                guard let tappedPosition else { return }
                
                self.memoTextView.isEditable = true
                self.memoTextViewTapGesture.isEnabled = false
                
                self.memoTextView.selectedTextRange = self.memoTextView.textRange(from: tappedPosition, to: tappedPosition)
                self.memoTextView.becomeFirstResponder()
            }
        }
    }
    
    
    private func shiftUpCell() {
        print(self.frame)
        guard let screenSize = UIScreen.current?.bounds.size else { fatalError() }
        guard let largeCardCollectionView = self.superview as? LargeCardCollectionView else { fatalError() }
        
        let cellUpperPadding = (self.collectionViewHeight - screenSize.height * 0.6) / 2
        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
        animator.addAnimations { [weak self] in
            guard let self else { fatalError() }
            
            //self.frame.origin.y의 기본값은 cellUpperPadding. 위로 shift하고 싶은 만큼 cellUpperPadding에서 빼 준다.
            //self.frame.origin.y = cellUpperPadding - self.keyboardFrame.height + self.cellLowerPadding
//            self.bounds.origin.y = self.keyboardFrame.height - cellUpperPadding
            self.frame.origin.y = -largeCardCollectionView.frame.origin.y + UIWindow.current!.safeAreaInsets.top
            self.frame.size.height = SizeContainer.screenSize.height - UIWindow.current!.safeAreaInsets.top - self.keyboardFrame.height
            
            self.titleTextField.textColor = .systemGray4
            self.heartImageView.tintColor = .systemGray4
            self.ellipsisButton.imageView?.tintColor = .systemGray4
        }
        
        animator.startAnimation()
    }
    
    
    private func shiftDownCell(completion: ((UIViewAnimatingPosition) -> Void)? = nil) {
        
        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
        guard let screenSize = UIScreen.current?.bounds.size else { fatalError() }
        let cellUpperPadding = (self.collectionViewHeight - screenSize.height * 0.6) / 2
        animator.addAnimations { [weak self] in
            guard let self else { fatalError() }
            self.frame.origin.y = cellUpperPadding
            self.frame.size.height = SizeContainer.screenSize.height * 0.6
//            self.bounds.origin.y = 0
            self.titleTextField.textColor = .label
            self.heartImageView.tintColor = .systemRed
            self.ellipsisButton.imageView?.tintColor = .currentTheme()
        }
        guard let completion else { return }
        animator.addCompletion(completion)
        
        animator.startAnimation()
    }
    
    
    
    
    private func setupDelegates() {
        self.titleTextField.delegate = self
        self.memoTextView.delegate = self
        
        self.selectedCategoryCollectionView.dataSource = self
        self.selectedCategoryCollectionView.delegate = self
        
        self.selectedImageCollectionView.dataSource = self
        self.selectedImageCollectionView.delegate = self
    }
    
    
    func setConstraints() {
        let contentViewWidthConstraint = self.contentView.widthAnchor.constraint(equalToConstant: SizeContainer.screenSize.width * 0.9)
        contentViewWidthConstraint.priority = UILayoutPriority(999)
        contentViewWidthConstraint.isActive = true
        
        self.contentViewHeightConstraint.priority = UILayoutPriority(rawValue: 999)
        self.contentViewHeightConstraint.isActive = true
//        self.contentView.heightAnchor.constraint(equalToConstant: SizeContainer.screenSize.height * 0.6).isActive = true
        
        self.memoDateLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -30).isActive = true
        self.memoDateLabel.bottomAnchor.constraint(equalTo: self.contentView.topAnchor, constant: -8).isActive = true
        
        self.titleTextField.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 15).isActive = true
        self.titleTextField.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 20).isActive = true
        self.titleTextField.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        self.heartImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 14).isActive = true
        self.heartImageView.leadingAnchor.constraint(equalTo: self.titleTextField.trailingAnchor, constant: 10).isActive = true
        self.heartImageView.widthAnchor.constraint(equalToConstant: 27).isActive = true
        self.heartImageView.heightAnchor.constraint(equalToConstant: 27).isActive = true
        
        self.ellipsisButton.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 14).isActive = true
        self.ellipsisButton.leadingAnchor.constraint(equalTo: self.heartImageView.trailingAnchor, constant: 0).isActive = true
        self.ellipsisButton.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -14).isActive = true
        self.ellipsisButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        self.ellipsisButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        self.selectedCategoryCollectionView.topAnchor.constraint(equalTo: self.titleTextField.bottomAnchor, constant: 6).isActive = true
        self.selectedCategoryCollectionView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 10).isActive = true
        self.selectedCategoryCollectionView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -10).isActive = true
        self.selectedCategoryCollectionView.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        self.selectedImageCollectionView.topAnchor.constraint(equalTo: self.selectedCategoryCollectionView.bottomAnchor, constant: 5).isActive = true
        self.selectedImageCollectionView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 10).isActive = true
        self.selectedImageCollectionView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -10).isActive = true
        self.selectedImageCollectionViewHeightConstraint.isActive = true
        
        self.memoTextView.topAnchor.constraint(equalTo: self.selectedImageCollectionView.bottomAnchor, constant: 10).isActive = true
        self.memoTextView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 10).isActive = true
        self.memoTextView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -10).isActive = true
        self.memoTextView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -10).isActive = true
        
        //self.labelMemo.topAnchor.constraint(equalTo: self.cardImageAndMemoCollectionView.bottomAnchor, constant: 0).isActive = true
        //self.labelMemo.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 0).isActive = true
        //self.labelMemo.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 0).isActive = true
    }
    
    
    private func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { fatalError() }
        self.keyboardFrame = keyboardFrame
        if self.memoTextView.isFirstResponder {
            self.shiftUpCell()
        }
    }
    
    
    @objc private func keyboardWillHide() {
        
        
        if self.titleTextField.isFirstResponder {
            self.updateTitleTextField()
            
        } else if self.memoTextView.isFirstResponder {
            self.memoTextView.isEditable = false
            self.memoTextViewTapGesture.isEnabled = true
            self.updateMemoTextView()
        }
        
        guard let orderCriterion = UserDefaults.standard.string(forKey: KeysForUserDefaults.orderCriterion.rawValue) else { fatalError() }
        guard let memoEntity else { fatalError() }
        if orderCriterion == OrderCriterion.creationDate.rawValue {
//            self.memoDateLabel.text = memoEntity.getCreationDateInString() + "에 생성됨"
            self.memoDateLabel.text = String(format: "%@에 생성됨".localized(), memoEntity.getCreationDateInString())
        } else {
//            self.memoDateLabel.text = memoEntity.getModificationDateString() + "에 수정됨"
            self.memoDateLabel.text = String(format: "%@에 수정됨".localized(), memoEntity.getModificationDateString())
        }
        
        self.shiftDownCell(completion: { [weak self, weak memoEntity] animatingPosition in
            guard let self else { fatalError() }
            guard let memoEntity else { fatalError() }
            if self.isEdited {
                
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
                memoEntity.memoTitle = self.titleTextField.text!
                memoEntity.memoText = self.memoTextView.text
                appDelegate.saveContext()
            }
        })
        
    }
    
    
    private func updateTitleTextField() {
        guard let memoEntity else { fatalError() }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
        if self.isTextFieldChanged {
            guard let text = self.titleTextField.text else { fatalError() }
            memoEntity.memoTitle = text
            memoEntity.modificationDate = Date()
        }
        appDelegate.saveContext()
    }
    
    
    private func updateMemoTextView() {
        guard let memoEntity else { fatalError() }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
        if self.isTextViewChanged {
            memoEntity.memoText = self.memoTextView.text
            memoEntity.modificationDate = Date()
        }
        appDelegate.saveContext()
    }
    
    
    func configureCell(memo: MemoEntity, collectionViewHeight: CGFloat, cellLowerPadding: CGFloat) {
        
        guard let orderCriterion = UserDefaults.standard.string(forKey: KeysForUserDefaults.orderCriterion.rawValue) else { fatalError() }
        
        self.memoEntity = memo
        if memo.isInTrash {
            self.memoDateLabel.textColor = .systemRed
            guard let deletedDate = memo.deletedDate else { fatalError() }
            let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
            let dateAfterDeleted = calendar.dateComponents([.day, .hour], from: deletedDate, to: Date())
            guard let dayAfterDeleted = dateAfterDeleted.day else { fatalError() }
            guard let hourAfterDeleted = dateAfterDeleted.hour else { fatalError() }
            
            if dayAfterDeleted < 13 {
                //self.memoDatelabel.text = "\(14 - dayAfterDeleted)일 뒤에 삭제됨"
                self.memoDateLabel.text = String(format: "%d일 뒤에 삭제됨".localized(), 14 - dayAfterDeleted)
            } else {
                self.memoDateLabel.text = "1일 이내에 삭제됨".localized()
            }
            
            self.titleTextField.isEnabled = false
            self.memoTextViewTapGesture.isEnabled = false
            self.memoTextView.isEditable = false
            self.memoTextView.isSelectable = false
            self.heartImageView.tintColor = .lightGray
            self.heartImageViewTapGesture.isEnabled = false
            self.ellipsisButton.menu = UIMenu(children: [self.restoreMemoAction, self.deleteMemoAction])
        } else {
            self.ellipsisButton.menu = UIMenu(children: [self.presentEditingModeAction, self.deleteMemoAction])
            if orderCriterion == OrderCriterion.creationDate.rawValue {
//                self.memoDateLabel.text = memo.getCreationDateInString() + "에 생성됨"
                self.memoDateLabel.text = String(format: "%@에 생성됨".localized(), memo.getCreationDateInString())
            } else {
//                self.memoDateLabel.text = memo.getModificationDateString() + "에 수정됨"
                self.memoDateLabel.text = String(format: "%@에 수정됨".localized(), memo.getModificationDateString())
            }
        }
        
        
        self.titleTextField.text = memo.memoTitle
        self.selectedCategoryCollectionView.reloadData()
        self.memoTextView.setLineSpace(with: memo.memoTextLongBuffer, lineSpace: 5, font: UIFont.systemFont(ofSize: 15))
        
        if memo.memoText.count > 5000 {
            DispatchQueue.global().async { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.memoTextView.setLineSpace(with: memo.memoText, lineSpace: 5, font: UIFont.systemFont(ofSize: 15))
                }
            }
        }
        
        self.memoTextView.sizeToFit()
        if UserDefaults.standard.object(forKey: "themeColor") as! String == ThemeColor.black.rawValue {
            self.memoTextView.linkTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.systemGray,
                NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]
        } else {
            self.memoTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.currentTheme()]
        }
        
        if self.contentView.traitCollection.userInterfaceStyle == .dark {
            self.layer.shadowColor = UIColor.clear.cgColor
        } else {
            self.layer.shadowColor = UIColor.currentTheme().cgColor
        }
        
        if memo.isFavorite {
            self.heartImageView.image = UIImage(systemName: "heart.fill")
        }
        self.collectionViewHeight = collectionViewHeight
        self.cellLowerPadding = cellLowerPadding
        
        
        self.loadImageEntities(of: memo)
        self.selectedImageCollectionView.reloadData()
    }
    
    
    func loadImageEntities(of memoEntity: MemoEntity) {
        self.sortedImageEntityArray = ImageEntityManager.shared.getImageEntities(from: memoEntity, inOrderOf: ImageOrderIndexKind.orderIndex)
        
        switch sortedImageEntityArray.count {
        case 0:
            self.selectedImageCollectionViewHeightConstraint.constant = 0
        default:
            //selectedImageCollectionView의 itemSize는(높이는) 100이다.
            self.selectedImageCollectionViewHeightConstraint.constant = 70
        }
        
        sortedImageEntityArray.forEach { [weak self] imageEntity in
            guard let self else { return }
            guard let thumbnail = self.imageEntityManager.getThumbnailImage(imageEntity: imageEntity) else { return }
            self.thumbnailArray.append(thumbnail)
        }
    }
    
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.memoEntity = nil
        self.sortedImageEntityArray = []
        self.thumbnailArray = []
        self.imageArray = []
        self.selectedImageCollectionView.reloadData()
        self.heartImageView.image = UIImage(systemName: "heart")
        self.titleTextField.tintColor = .currentTheme()
        self.titleTextField.inputAccessoryView?.tintColor = .currentTheme()
        self.memoTextView.tintColor = .currentTheme()
        self.memoTextView.inputAccessoryView?.tintColor = .currentTheme()
        self.isTextFieldChanged = false
        self.isTextViewChanged = false
        self.isEdited = false
    }
    
    
    @objc private func keyboardHideButtonTapped() {
        self.endEditing(true)
        self.shiftDownCell()
    }
    
    
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
    
    
}


extension LargeCardCollectionViewCell: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
        
//        if collectionView == self.selectedCategoryCollectionView {
//            return 1
//        } else {
//            return 1
//        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == self.selectedCategoryCollectionView {
            let categoriesArray = self.categoryEntityManager.getCategoryEntities(memo: self.memoEntity, inOrderOf: CategoryProperties.modificationDate, isAscending: false)
            return categoriesArray.count
            
        } else {
//            if section == 0 {
                let thumbnailCount = self.thumbnailArray.count
                return thumbnailCount
//            } else {
//                return 1
//            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == self.selectedCategoryCollectionView {
            
            let categoriesArray = self.categoryEntityManager.getCategoryEntities(memo: self.memoEntity, inOrderOf: CategoryProperties.modificationDate, isAscending: false)
            let cell = self.selectedCategoryCollectionView.dequeueReusableCell(withReuseIdentifier: TotalListCellCategoryCell.cellID, for: indexPath) as! TotalListCellCategoryCell
            cell.categoryLabel.text = categoriesArray[indexPath.row].name
            return cell
            
            //if collectionView == self.cardImageAndMemoCollectionView {
        } else {
            //            if indexPath.section == 0 {
            
            let cell = self.selectedImageCollectionView.dequeueReusableCell(withReuseIdentifier: MemoImageCollectionViewCell.cellID, for: indexPath) as! MemoImageCollectionViewCell
            cell.imageView.image = self.thumbnailArray[indexPath.row]
            
            return cell
            
            //            // else if indexPath.section == 1 {
            //            } else {
            //                let cell = self.cardImageAndMemoCollectionView.dequeueReusableCell(withReuseIdentifier: MemoCompositionalTextCell.cellID, for: indexPath) as! MemoCompositionalTextCell
            //                //cell.textView.text = self.memoEntity?.memoText
            //                if let memoText = self.memoEntity?.memoText {
            //                    cell.textView.setLineSpace(with: memoText, lineSpace: 4.5, font: UIFont.systemFont(ofSize: 13.5))
            //                }
            ////                if memoEntity?.images?.count == 0 {
            ////                    cell.textView.isScrollEnabled = true
            ////                }
            //
            //                return cell
            //            }
            
        }
    }
    
    
    
}


extension LargeCardCollectionViewCell: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if self.isCellShiftedUp {
            self.shiftDownCell()
            self.updateMemoTextView()
        }
        self.memoTextView.isEditable = false
        self.memoTextViewTapGesture.isEnabled = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        print(#function)
        self.updateTitleTextField()
    }
    
}




extension LargeCardCollectionViewCell: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        self.isTextViewChanged = true
        self.isEdited = true
    }
    
    
    //왠지 모르겠는데 textView의 editing이 끝나도 이 메서드 호출되지 않는다...
    func textViewDidEndEditing(_ textView: UITextView) {
        print(#function)
    }
    
}



extension LargeCardCollectionViewCell: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let delegate else { return }
        guard collectionView == self.selectedImageCollectionView else { return }
        self.endEditing(true)
        delegate.triggerPresentMethod(selectedItemAt: indexPath, imageEntitiesArray: self.sortedImageEntityArray)
    }
    
}


extension LargeCardCollectionViewCell: UIGestureRecognizerDelegate {
    
}
