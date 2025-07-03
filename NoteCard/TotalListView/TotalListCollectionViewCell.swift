//
//  TotalListTableViewCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/17.
//

import UIKit

class TotalListCollectionViewCell: UICollectionViewCell {
    
    static var cellID: String {
        String(describing: self)
    }
    
    let categoryEntityManager = CategoryEntityManager.shared
    let memoEntityManager = MemoEntityManager.shared
    let heartTapGesture = UITapGestureRecognizer()
    let longPressGesture = UILongPressGestureRecognizer()
    let screenSize = UIScreen.current!.bounds.size
    
    
    var memoEntity: MemoEntity? = nil
    
//    let titleTextField: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 18)
//        label.textAlignment = .left
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
    
    lazy var titleTextField: UITextField = { [weak self] in
        guard let self else { fatalError() }
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 18)
        textField.placeholder = "제목 없음".localized()
        textField.borderStyle = .none
        textField.text = ""
        textField.textAlignment = .left
        textField.backgroundColor = .clear
        textField.textColor = .label
        textField.isEnabled = false
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
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let selectedCategoryCollectionView: UICollectionView = {
        let flowLayout: UICollectionViewFlowLayout = {
            let layout = UICollectionViewFlowLayout()
            layout.minimumLineSpacing = 10
            layout.scrollDirection = .horizontal
            layout.estimatedItemSize = CGSize(width: 50, height: 25)
            return layout
        }()
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.register(TotalListCellCategoryCell.self, forCellWithReuseIdentifier: TotalListCellCategoryCell.cellID)
        collectionView.clipsToBounds = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    
    
    let memoTextView: UITextView = {
//        let textView = UITextView(usingTextLayoutManager: false)
//        let textView = UITextView()
        
        var textView: UITextView
        
        if #available(iOS 16.0, *) {
            textView = UITextView(usingTextLayoutManager: false)
        } else {
            textView = UITextView()
        }
        
        textView.backgroundColor = .clear
        textView.bounces = true
        textView.isEditable = false
        textView.textAlignment = .left
        textView.isScrollEnabled = false
        textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        
        textView.clipsToBounds = true
//        textView.layer.cornerRadius = 11
        textView.layer.cornerRadius = 0
        textView.layer.cornerCurve = .continuous
        textView.layer.maskedCorners = CACornerMask(arrayLiteral: .layerMaxXMaxYCorner, .layerMinXMaxYCorner)
        
        textView.isSelectable = true
        textView.isUserInteractionEnabled = false
        textView.dataDetectorTypes = .link
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    
    lazy var memoTextViewDynamicHeightConstraint = self.memoTextView.heightAnchor.constraint(lessThanOrEqualToConstant: 87)
    lazy var memoTextViewStaticHeightConstraint = self.memoTextView.heightAnchor.constraint(equalToConstant: 18)
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        setupConstraints()
        setupDelegates()
        setupGestureRecognizers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.contentView.traitCollection.userInterfaceStyle == .dark {
            self.layer.shadowPath = nil
            self.layer.shadowColor = nil
            
        } else {
            let roundBezierPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height), cornerRadius: 20)
            self.layer.shadowPath = roundBezierPath.cgPath
            self.layer.shadowColor = UIColor.currentTheme().cgColor
            self.layer.shadowOffset = CGSize(width: 0, height: 0)
            self.layer.shadowOpacity = 0.1
            self.layer.shadowRadius = 8
            
        }
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.titleTextField.text = ""
        self.memoTextView.setLineSpace(with: "", lineSpace: 5, font: UIFont.systemFont(ofSize: 15))
    }
    
    private func setupUI() {
        self.backgroundColor = .clear
        
        self.contentView.clipsToBounds = true
        self.contentView.layer.cornerRadius = 20
        self.contentView.layer.cornerCurve = .continuous
        
        self.contentView.backgroundColor = UIColor.memoBackground
        self.contentView.addSubview(self.titleTextField)
        self.contentView.addSubview(self.heartImageView)
        self.contentView.addSubview(self.selectedCategoryCollectionView)
//        self.contentView.addSubview(self.memoTextLabel)
        self.contentView.addSubview(self.memoTextView)
        self.contentView.isUserInteractionEnabled = true
    }
    
    
    private func setupConstraints() {
        let widthConstraint = self.contentView.widthAnchor.constraint(equalToConstant: CGSizeConstant.screenSize.width * 0.95)
        widthConstraint.priority = UILayoutPriority.init(751)
        widthConstraint.isActive = true
//        self.contentView.widthAnchor.constraint(equalToConstant: CGSizeConstant.screenSize.width * 0.95).isActive = true
//        self.contentView.widthAnchor.constraint(equalToConstant: CGSizeConstant.screenSize.width * 0.95).priority = .init(999)
//        self.contentView.widthAnchor.constraint(equalToConstant: 300).isActive = true
        
        self.titleTextField.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 6).isActive = true
        self.titleTextField.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 15).isActive = true
        //self.memoTitleLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -15).isActive = true
        self.titleTextField.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        self.heartImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10).isActive = true
        self.heartImageView.leadingAnchor.constraint(equalTo: self.titleTextField.trailingAnchor, constant: 10).isActive = true
        self.heartImageView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -10).isActive = true
        self.heartImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        self.heartImageView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        self.selectedCategoryCollectionView.topAnchor.constraint(equalTo: self.titleTextField.bottomAnchor, constant: 10).isActive = true
        self.selectedCategoryCollectionView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 10).isActive = true
        self.selectedCategoryCollectionView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -10).isActive = true
        self.selectedCategoryCollectionView.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        self.memoTextView.topAnchor.constraint(equalTo: self.selectedCategoryCollectionView.bottomAnchor, constant: 10).isActive = true
        self.memoTextView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 10).isActive = true
        self.memoTextView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -10).isActive = true
        self.memoTextView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -10).isActive = true
//        self.memoTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 18).isActive = true
        let textViewHeightConstraint = self.memoTextView.heightAnchor.constraint(lessThanOrEqualToConstant: 87)
        textViewHeightConstraint.priority = UILayoutPriority(751)
        textViewHeightConstraint.isActive = true
        
    }
    
    
    private func setupDelegates() {
        self.selectedCategoryCollectionView.dataSource = self
        self.selectedCategoryCollectionView.delegate = self
        
        self.longPressGesture.delegate = self
    }
    
    private func setupGestureRecognizers() {
        self.longPressGesture.isEnabled = true
        self.longPressGesture.minimumPressDuration = 0.0
        self.longPressGesture.cancelsTouchesInView = false
        self.longPressGesture.delegate = self
        
        self.heartTapGesture.addTarget(self, action: #selector(heartImageViewTapped))
        self.longPressGesture.addTarget(self, action: #selector(handleLongPressGesture))
        
        self.contentView.addGestureRecognizer(self.longPressGesture)
        self.heartImageView.addGestureRecognizer(self.heartTapGesture)
    }
    
    @objc private func heartImageViewTapped() {
        print(#function)
        guard let memoEntity else {
            fatalError("memoEntity of cell is nil")
        }
        self.memoEntityManager.togglesFavorite(in: memoEntity)
        switch memoEntity.isFavorite {
        case true:
            self.heartImageView.image = UIImage(systemName: "heart.fill")
        case false:
            self.heartImageView.image = UIImage(systemName: "heart")
        }
    }
    
    @objc private func handleLongPressGesture(gesture: UILongPressGestureRecognizer) {
        
        switch gesture.state {
        case .began:
            let animator = UIViewPropertyAnimator(duration: 0.6, controlPoint1: CGPoint(x: 0.15, y: 1), controlPoint2: CGPoint(x: 0.25, y: 1.0))
            animator.addAnimations {
                self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            }
            animator.startAnimation()
            
        case .changed:
            let animator = UIViewPropertyAnimator(duration: 0.3, controlPoint1: CGPoint(x: 0.3, y: 0.25), controlPoint2: CGPoint(x: 0.25, y: 1.0))
            animator.addAnimations {
                self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
            animator.startAnimation()
            
            //to cancel the longPressGestureRecognizer so that the PopupView will not be presented after touches end.
            gesture.isEnabled = false
            gesture.isEnabled = true
            
        case .ended:
            let animator = UIViewPropertyAnimator(duration: 0.2, curve: UIView.AnimationCurve.easeInOut)
            animator.addAnimations {
                self.transform = CGAffineTransform.identity
                self.selectedCategoryCollectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
            }
            animator.startAnimation()
            NotificationCenter.default.post(name: NSNotification.Name("cellSelectedNotification"), object: nil, userInfo: ["cell": self])
            
        default:
            let animator = UIViewPropertyAnimator(duration: 0.2, curve: UIView.AnimationCurve.easeInOut)
            animator.addAnimations {
                self.transform = CGAffineTransform.identity
            }
            animator.startAnimation()
        }
    }
    
    
    
    func configureCell(with memoEntity: MemoEntity) {
        self.memoEntity = memoEntity
        
        self.titleTextField.text = memoEntity.memoTitle
        self.memoTextView.setLineSpace(with: memoEntity.memoTextShortBuffer, lineSpace: 5, font: UIFont.systemFont(ofSize: 15), textColor: .label)
        if UserDefaults.standard.object(forKey: "themeColor") as! String == ThemeColor.black.rawValue {
            self.memoTextView.linkTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.systemGray,
                NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        } else {
            self.memoTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.currentTheme()]
        }
        switch self.memoEntity!.isFavorite {
        case true:
            self.heartImageView.image = UIImage(systemName: "heart.fill")
        case false:
            self.heartImageView.image = UIImage(systemName: "heart")
        }
        
        self.selectedCategoryCollectionView.reloadData()
    }
    
    
}


extension TotalListCollectionViewCell: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let categoriesArray = self.categoryEntityManager.getCategoryEntities(memo: self.memoEntity, inOrderOf: CategoryProperties.modificationDate, isAscending: false)
        if self.memoEntity != nil {
            return categoriesArray.count
            
        } else {
            return 0
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let categoriesArray = self.categoryEntityManager.getCategoryEntities(
            memo: self.memoEntity,
            inOrderOf: CategoryProperties.modificationDate,
            isAscending: false
        )
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TotalListCellCategoryCell.cellID, for: indexPath) as? TotalListCellCategoryCell else {
            fatalError("TotalListCellCategoryCell dequeueing failed.")
        }
        
        cell.configure(with: categoriesArray[indexPath.row])
        return cell
        
    }
    
    
    
}

extension TotalListCollectionViewCell: UICollectionViewDelegate {
    
}

extension TotalListCollectionViewCell: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return true
    }
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchedView = touch.view else { return false }
        if touchedView == self.heartImageView {
            return false
        } else {
            return true
        }
    }
    
}
