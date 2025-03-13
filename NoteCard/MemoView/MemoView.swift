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
    
    lazy var categoryNameTextFieldTopConstraint = self.categoryNameTextField.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 0)
    lazy var smallCardCollectionViewBottomConstraint = self.smallCardCollectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0)
    
    lazy var categoryNameTextField: UITextField = { [weak self] in
        guard let self else { fatalError() }
        
        let textField = UITextField()
        textField.placeholder = ""
        textField.borderStyle = .none
        textField.tintColor = .currentTheme()
        textField.textAlignment = .center
        textField.font = UIFont.boldSystemFont(ofSize: 35)
        textField.adjustsFontSizeToFitWidth = true
        textField.minimumFontSize = 27
        
        let bar = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        let hideKeyboardButton = UIBarButtonItem(image: UIImage(systemName: "keyboard.chevron.compact.down"), style: .plain, target: self, action: #selector(keyboardHideButtonTapped))
        let flexibleBarButton = UIBarButtonItem(systemItem: UIBarButtonItem.SystemItem.flexibleSpace)
        bar.items = [flexibleBarButton, hideKeyboardButton]
        bar.sizeToFit()
        bar.tintColor = .currentTheme()
        textField.inputAccessoryView = bar
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    
    let segmentControl: UISegmentedControl = {
//        let sc = UISegmentedControl(items: ["카드 형식", "격자 형식"])
//        rectangle.portrait.on.rectangle.portrait.angled
        let sc = UISegmentedControl(items: [
            UIImage(systemName: "rectangle.portrait.arrowtriangle.2.outward")!,
            UIImage(systemName: "rectangle.grid.3x2")!])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()
    
    
    //BlurView 의 애니메이션을 위해서는 어차피 매번 없애고 새로 생겨야 한다.
    //이 blurView 상수는 처음 한 번 만을 위해 만들어진 상수인 것임.
    //그래서 아예 setupUI() 함수 안에서 만들고 거기서 사라지게 놔눠도 괜찮지 않을까 생각했지만, 어차피 constraint도 설정해 주어야 하는 등 번거로운 게 많아서 그냥 이렇게 만들었음.
    //어차피 animationController(MemoViewPopupCardAnimatedTransitioning 프로토콜 타입) 에서 removeFromSuperView 하면서 사라질껄....? 아닌가...?
    var blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.systemThickMaterial)
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let viewUnderNaviBar: UIView = {
        let view = UIView()
        view.backgroundColor = .memoViewBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    
    
    /*
     lazy var compositinalLayout: UICollectionViewCompositionalLayout = { [weak self] in
        guard let self else { fatalError() }
        guard let screenWidth: CGFloat = UIScreen.current?.bounds.width else { fatalError() }
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.8), heightDimension: .fractionalHeight(1.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 18
        section.orthogonalScrollingBehavior = UICollectionLayoutSectionOrthogonalScrollingBehavior.groupPagingCentered
        
//        orthogonalScrollingBehavior를 groupPagingCentered로 설정하면 groupSize의 fractionWidth가 0.8보다 클 경우 빠르게 스크롤 하다가 두 번 스크롤이 되는 버그가 있음.
//        그래서 card의 너비를 키우고 싶어도 너비를 키울 수 없었음.
//        그래서 낸 결론이 groupSize의 fractionWidth의 값은 0.8을 유지한 채, CGAffineTransform을 이용해서 강제로 늘려서 키우는 것(?) 이다!
//        그래서 글자도 원래보다 조금씩 줄였음...
//        아핀 변환으로 너무 크게 키우면 글자가 흐려지겠지만(아닐 수도...?), scale을 1.1로만 설정해서 엄청 크게 크진 않으므로 큰 문제는 되지 않을 듯...?
        section.visibleItemsInvalidationHandler = { (visibleItems, offset, env) -> Void in
            let containerWidth = env.container.contentSize.width
//            이 상황에서는 visibleItems의 요소들은 모두 헤더나 푸터가 아닌 item들이다.
            visibleItems.forEach { item in
                let itemCenterXFromOffset = item.frame.midX - offset.x
                let xDifferenceFromCenter = itemCenterXFromOffset - (containerWidth/2)
                let xDistanceFromCenter = abs((itemCenterXFromOffset - containerWidth/2))
        
                let minScale: CGFloat = 0.9
                let maxScale: CGFloat = 1.0
//                let scale = max(maxScale - (xDistanceFromCenter / contentWidth), minScale)
                let scale = 1.1 - ( 2 * (maxScale - minScale) / containerWidth * xDistanceFromCenter )
                
                item.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        }
        
        return UICollectionViewCompositionalLayout(section: section)
    }()
    */
    
    lazy var screenSize = UIScreen.current?.bounds.size
    
    
    lazy var pagingFlowLayout: UICollectionViewFlowLayout = { [weak self] in
        guard let self else { fatalError() }
        guard let screenSize else { fatalError() }
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
//        layout.itemSize = CGSize(width: 300, height: 500)
        layout.estimatedItemSize = CGSize(width: screenSize.width * 0.9, height: screenSize.height * 0.5)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 0
        return layout
    }()
    
    lazy var largeCardCollectionView: LargeCardCollectionView = { [weak self] in
        guard let self else { fatalError() }
        guard let screenSize else { fatalError() }
        let collectionView = LargeCardCollectionView(frame: CGRect.zero, collectionViewLayout: self.pagingFlowLayout)
        collectionView.clipsToBounds = false
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 0, left: screenSize.width * 0.05, bottom: 0, right: screenSize.width * 0.05)
        collectionView.register(
            LargeCardCollectionViewCell.self,
            forCellWithReuseIdentifier: LargeCardCollectionViewCell.cellID
        )
        collectionView.isScrollEnabled = true
        collectionView.decelerationRate = .fast
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    
    
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        guard let screenSize else { fatalError() }
        
        let layout = UICollectionViewFlowLayout()
        //layout.sectionInset = UIEdgeInsets(top: 15, left: 15, bottom: 0, right: 0)
        let interCardSpacing:CGFloat = 10
        let cardWidth = ((screenSize.width - (interCardSpacing * 4)) / 3).rounded(FloatingPointRoundingRule.down)
        layout.minimumInteritemSpacing = interCardSpacing
        layout.minimumLineSpacing = interCardSpacing
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        layout.itemSize = CGSize(width: cardWidth, height: cardWidth * 1.5)
        return layout
    }()
    
    lazy var smallCardCollectionView: UICollectionView = { [weak self] in
        guard let self else { return UICollectionView(frame: CGRect.zero) }
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.flowLayout)
        collectionView.isHidden = true
        collectionView.layer.masksToBounds = false
        collectionView.clipsToBounds = true
        collectionView.allowsMultipleSelectionDuringEditing = true
        collectionView.layer.cornerRadius = 13
        collectionView.layer.cornerCurve = .continuous
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 150, left: 10, bottom: 10, right: 10)
        collectionView.register(
            SmallCardCollectionViewCell.self,
            forCellWithReuseIdentifier: SmallCardCollectionViewCell.cellID
        )
        collectionView.isScrollEnabled = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        return collectionView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        setupConstraints()
        setupObserver()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
//        self.gradientLayer.frame = self.gradientView.bounds
//        self.gradientView.layer.addSublayer(self.gradientLayer)
    }
    
    private func setupUI() {
        self.clipsToBounds = true
        self.backgroundColor = UIColor.memoViewBackground
        
        self.addSubview(smallCardCollectionView)
        self.addSubview(blurView)
        
        self.addSubview(viewUnderNaviBar)
        
        self.addSubview(categoryNameTextField)
        self.addSubview(segmentControl)
        
        self.addSubview(largeCardCollectionView)
    }
    
    
    func setupConstraints() {
        
//        categoryNameTextField.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        self.categoryNameTextFieldTopConstraint.isActive = true
        categoryNameTextField.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true
        categoryNameTextField.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -20).isActive = true
        categoryNameTextField.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        
        //segmentControl.topAnchor.constraint(equalTo: self.categoryNameLabel.bottomAnchor, constant: 20).isActive = true
        segmentControl.topAnchor.constraint(equalTo: self.categoryNameTextField.bottomAnchor, constant: 20).isActive = true
        segmentControl.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        
        blurView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        blurView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0).isActive = true
        blurView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0).isActive = true
        blurView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
        viewUnderNaviBar.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        viewUnderNaviBar.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0).isActive = true
        viewUnderNaviBar.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0).isActive = true
        viewUnderNaviBar.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
//        gradientView.topAnchor.constraint(equalTo: self.blurView.topAnchor, constant: 0).isActive =  true
//        gradientView.leadingAnchor.constraint(equalTo: self.blurView.leadingAnchor, constant: 0).isActive =  true
//        gradientView.trailingAnchor.constraint(equalTo: self.blurView.trailingAnchor, constant: 0).isActive =  true
//        gradientView.bottomAnchor.constraint(equalTo: self.blurView.bottomAnchor, constant: 0).isActive =  true
        
//        memoCompositionalCollectionView.topAnchor.constraint(equalTo: self.categoryNameTextField.bottomAnchor, constant: 100).isActive = true
        largeCardCollectionView.topAnchor.constraint(equalTo: self.segmentControl.bottomAnchor, constant: 0).isActive = true
        largeCardCollectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0).isActive = true
        largeCardCollectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0).isActive = true
        largeCardCollectionView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        
//        smallCardCollectionView.topAnchor.constraint(equalTo: self.categoryNameTextField.bottomAnchor, constant: 85).isActive = true
        smallCardCollectionView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        smallCardCollectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0).isActive = true
        smallCardCollectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0).isActive = true
//        smallCardCollectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
        self.smallCardCollectionViewBottomConstraint.isActive = true
    }
    
    private func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(kayboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
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


