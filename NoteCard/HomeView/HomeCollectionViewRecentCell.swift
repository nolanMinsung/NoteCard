//
//  HomeCollectionViewRecentCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class HomeCollectionViewRecentCell: UICollectionViewCell {
    
    static var cellID: String {
        return String(describing: self)
    }
    
    var memoEntity: MemoEntity? //{
    //        didSet {
    //            configureUIWithData()
    //        }
    //    }
    
    
    let longPressGesture = UILongPressGestureRecognizer()
    
    
    var titleTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.placeholder = "제목 없음"
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.textColor = .label
        textField.textAlignment = .center
        textField.isEnabled = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    
    let pictureImageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .left
        label.numberOfLines = 1
        label.text = "🏞️"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let imageCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textAlignment = .left
        label.numberOfLines = 1
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .right
        label.numberOfLines = 1
        label.textColor = .label
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    let memoTextView: UITextView = {
        let textView: UITextView
        if #available(iOS 16.0, *) {
            textView = UITextView(usingTextLayoutManager: false)
        } else {
            textView = UITextView()
        }
        //textView.font = UIFont.systemFont(ofSize: 12)
        textView.textAlignment = .left
        textView.backgroundColor = .clear
        textView.clipsToBounds = true
        textView.layer.cornerRadius = 7
        textView.layer.cornerCurve = .continuous
        textView.isUserInteractionEnabled = false
        textView.contentInset.top = 0
        textView.textContainerInset.top = 4
        //textView.isScrollEnabled = true
        //textView.isEditable = false
        //textView.isSelectable = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupDelegates()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.contentView.traitCollection.userInterfaceStyle == .dark {
            self.layer.shadowPath = nil
            self.layer.shadowColor  = nil
            
        } else {
            
            let roundBezierPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 3, width: 145, height: 220), cornerRadius: 20)
//            let roundBezierPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 12)
            self.layer.shadowPath = roundBezierPath.cgPath
            self.layer.shadowOpacity = 0.2
            self.layer.shadowRadius = 5
            self.layer.shadowColor = UIColor.currentTheme().cgColor
        }
    }
    
    override func prepareForReuse() {
        self.titleTextField.textColor = .label
        self.pictureImageLabel.alpha = 1
        self.imageCountLabel.alpha = 1
    }
    
    
    
    func setupUI() {
        //cell의 contentView의 backgroundColor 대신에 cell의 backgroundColor에 직접 색을 넣어주는 이유는
        //팝업카드가 올라왔을 때 다크모드가 바뀌어도 셀 스냅샷의 배경을 투명하게 함으로써 최대한 덜 어색하게 보이게 하기 위함
        self.backgroundColor = UIColor.memoBackground
        self.clipsToBounds = true
        self.layer.masksToBounds = false
        self.layer.cornerRadius = 20
        self.layer.cornerCurve = .continuous
        
        self.contentView.addSubview(self.titleTextField)
        self.contentView.addSubview(self.pictureImageLabel)
        self.contentView.addSubview(self.imageCountLabel)
        self.contentView.addSubview(self.dateLabel)
        self.contentView.addSubview(self.memoTextView)
        
    }
    
    
    func configureCell(with memo: MemoEntity) {
        
        guard let orderCriterion = UserDefaults.standard.string(forKey: KeysForUserDefaults.orderCriterion.rawValue) else { fatalError() }
        
        self.memoEntity = memo
        self.titleTextField.text = memo.memoTitle
        self.imageCountLabel.text = String(memo.images.count)
        
        if orderCriterion == OrderCriterion.creationDate.rawValue {
            self.dateLabel.text = memo.getCreationDateInString()
        } else {
            self.dateLabel.text = memo.getModificationDateString()
        }
        
//        self.memoTextView.text = memo.memoText
        self.memoTextView.setLineSpace(with: memo.memoTextShortBuffer, lineSpace: 2, font: UIFont.systemFont(ofSize: 12))
        
        if memo.images.count == 0 {
            self.pictureImageLabel.alpha = 0.5
            self.imageCountLabel.alpha = 0.5
        }
        self.layoutSubviews()
    }
    
    
    func setupConstraints() {
        self.titleTextField.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 9).isActive = true
        self.titleTextField.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8).isActive = true
        self.titleTextField.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8).isActive = true
        
        self.pictureImageLabel.topAnchor.constraint(equalTo: self.titleTextField.bottomAnchor, constant: 5).isActive = true
        self.pictureImageLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 6).isActive = true
        self.pictureImageLabel.heightAnchor.constraint(equalToConstant: 18).isActive = true
        self.pictureImageLabel.widthAnchor.constraint(equalToConstant: 18).isActive = true
        
        self.imageCountLabel.leadingAnchor.constraint(equalTo: self.pictureImageLabel.trailingAnchor, constant: 1).isActive = true
        self.imageCountLabel.bottomAnchor.constraint(equalTo: self.pictureImageLabel.bottomAnchor, constant: 0).isActive = true
        self.imageCountLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 25).isActive = true
        
        self.dateLabel.leadingAnchor.constraint(equalTo: self.imageCountLabel.trailingAnchor, constant: 7).isActive = true
        self.dateLabel.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -6).isActive = true
        self.dateLabel.bottomAnchor.constraint(equalTo: self.pictureImageLabel.bottomAnchor, constant: 0).isActive = true
        
        self.memoTextView.topAnchor.constraint(equalTo: self.pictureImageLabel.bottomAnchor, constant: 4).isActive = true
        self.memoTextView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 7).isActive = true
        self.memoTextView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -7).isActive = true
        self.memoTextView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -7).isActive = true
    }
    
    
    private func setupDelegates() {
        self.longPressGesture.delegate = self
    }
    
    
    private func setupGesture() {
        self.longPressGesture.cancelsTouchesInView = false
        self.longPressGesture.minimumPressDuration = 0.0
        self.contentView.addGestureRecognizer(self.longPressGesture)
        self.longPressGesture.addTarget(self, action: #selector(handleLongPressGesture))
    }
    
    
    @objc private func handleLongPressGesture(gesture: UILongPressGestureRecognizer) {
        
        switch gesture.state {
        case .began:
            let animator = UIViewPropertyAnimator(duration: 0.6, controlPoint1: CGPoint(x: 0.15, y: 1), controlPoint2: CGPoint(x: 0.25, y: 1.0))
            animator.addAnimations { [weak self] in
                guard let self else { fatalError() }
                self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }
            animator.startAnimation()
            
        default:
            let animator = UIViewPropertyAnimator(duration: 0.3, controlPoint1: CGPoint(x: 0.3, y: 0.25), controlPoint2: CGPoint(x: 0.25, y: 1.0))
            animator.addAnimations { [weak self] in
                guard let self else { fatalError() }
                self.transform = CGAffineTransform.identity
            }
            animator.startAnimation()
        }
    }
    
    
}



extension HomeCollectionViewRecentCell: UIGestureRecognizerDelegate {
    
    //Cell에 longPressGesture를 추가하면 그 상위 뷰인 collection view 에 적용하는 다른 제스쳐가 안 먹힌다.
    //여기서 말하는 '다른 제스쳐' 란, collection view를 스크롤 하는 행위를 말한다. (그럼 scroll 이 gestureRecognizer란 말이냐?!! 그렇다!!)
    //추측컨데, 아마 UICollectionView의 scroll도 내부적으로 UIPanGesture로 인식해서 처리하나봄...
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

