//
//  CardFlowCollectionViewCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class SmallCardCollectionViewCell: UICollectionViewCell {
    
    static var cellID: String {
        return String(describing: self)
    }
    
    private lazy var feedbackGenerator: UIImpactFeedbackGenerator = {
        let generator: UIImpactFeedbackGenerator
        if #available(iOS 17.5, *) {
            generator = UIImpactFeedbackGenerator(style: .medium, view: self)
        } else {
            generator = UIImpactFeedbackGenerator(style: .medium)
        }
        generator.prepare()
        return generator
    }()
    
    var gestureInitialLocation: CGPoint!
    
    var onLongPressSelected: (() -> Void)? = nil
    
    override var isHighlighted: Bool {
        didSet {
            UIView.springAnimate(withDuration: 0.3) { [weak self] in
                guard let self else { return }
                self.transform = self.isHighlighted ? .init(scaleX: 0.95, y: 0.95) : .identity
            }
        }
    }
    
    override var isSelected: Bool {
        didSet {
            UIView.animate(
                withDuration: 0.2,
                delay: 0,
                options: [.curveEaseOut, .allowUserInteraction]
            ) { [weak self] in
                guard let self else { return }
                self.layer.borderColor = UIColor.currentTheme.cgColor
                self.layer.borderWidth = self.isSelected ? 2.0 : 0.0
                self.opaqueView.alpha = self.isSelected ? 0.0 : 0.7
            }
        }
    }
    
    private let memoManager = MemoEntityManager.shared
    private var longPressGestureToInflate = UILongPressGestureRecognizer()
    private let inflateAnimator = UIViewPropertyAnimator(
        duration: 0.4,
        controlPoint1: CGPoint(x: 0.2, y: 0.5),
        controlPoint2: CGPoint(x: 0.2, y: 0.6)
    )
    var memoEntity: MemoEntity?
    private(set) var memo: Memo?
    
    let opaqueView = UIView()
    private let titleTextLabel = UITextField()
    private let memoTextLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setConstraints()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.borderColor = UIColor.currentTheme.cgColor
        
        if self.contentView.traitCollection.userInterfaceStyle == .dark {
            self.layer.shadowPath = nil
            self.layer.shadowColor = nil
            
        } else {
            let bezierPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 12)
            self.layer.shadowPath = bezierPath.cgPath
            self.layer.shadowOffset = CGSize(width: 0, height: 0)
            self.layer.shadowColor = UIColor.currentTheme.cgColor
            self.layer.shadowOpacity = 0.3
            self.layer.shadowRadius = 4
        }
        
        guard let smallCardCollectionView = self.superview as? UICollectionView else { return }
        self.longPressGestureToInflate.isEnabled = smallCardCollectionView.isEditing
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func setupUI() {
        self.backgroundColor = UIColor.memoBackground
        self.clipsToBounds = true
        // 셀 주변의 그라데이션 설정을 위해 명시적으로 layer.masksToBounds = false로 설정
        self.layer.masksToBounds = false
        self.layer.cornerRadius = 13
        self.layer.cornerCurve = .continuous
        
        self.contentView.addSubview(titleTextLabel)
        self.contentView.addSubview(memoTextLabel)
        self.contentView.addSubview(opaqueView)
        
        titleTextLabel.isEnabled = false
        titleTextLabel.borderStyle = .none
        titleTextLabel.placeholder = "제목 없음".localized()
        titleTextLabel.font = UIFont.systemFont(ofSize: 15)
        titleTextLabel.textColor = .label
        titleTextLabel.textAlignment = .center
        
        memoTextLabel.textAlignment = .left
        memoTextLabel.clipsToBounds = true
        memoTextLabel.backgroundColor = .clear
        memoTextLabel.layer.cornerRadius = 7
        memoTextLabel.layer.cornerCurve = .continuous
//        memoTextLabel.font = .systemFont(ofSize: 12)
        memoTextLabel.font = .preferredFont(forTextStyle: .footnote)
        memoTextLabel.numberOfLines = 0
//        memoTextView.isUserInteractionEnabled = false
//        memoTextView.contentInset.top = 0
//        memoTextView.textContainerInset.top = 4
        
        opaqueView.backgroundColor = .memoCellOpaqueView
        opaqueView.alpha = 0
        // 셀 주변의 그라데이션 설정을 위해 셀의 layer.masksToBounds에 명시적으로 false를 할당했으므로 아래처럼 직접 cornerRadius를 설정해주었음.
        opaqueView.clipsToBounds = true
        opaqueView.layer.cornerRadius = 13
        opaqueView.layer.cornerCurve = .continuous
    }
    
    func configureCell(with memo: MemoEntity) {
        self.memoEntity = memo
        self.titleTextLabel.text = memo.memoTitle
        self.memoTextLabel.text = memo.memoText
//        self.memoTextView.setLineSpace(with: memo.memoText, lineSpace: 2, font: UIFont.systemFont(ofSize: 12))
    }
    
    func configure(with memo: Memo) {
        self.memo = memo
        titleTextLabel.text = memo.memoTitle
        memoTextLabel.text = String(memo.memoText.prefix(200))
        
        layer.borderColor = UIColor.currentTheme.cgColor
        layer.borderWidth = isSelected ? 2.0 : 0.0
        opaqueView.alpha = isSelected ? 0.0 : 0.7
    }
    
    func setConstraints() {
        titleTextLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleTextLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            titleTextLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            titleTextLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            titleTextLabel.heightAnchor.constraint(equalToConstant: 20),
        ])
        
        memoTextLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            memoTextLabel.topAnchor.constraint(equalTo: titleTextLabel.bottomAnchor, constant: 7),
            memoTextLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 7),
            memoTextLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -7),
            memoTextLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -7),
        ])
        
        opaqueView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            opaqueView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            opaqueView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            opaqueView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            opaqueView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
        ])
    }
    
    private func setupGesture() {
        self.contentView.addGestureRecognizer(self.longPressGestureToInflate)
        
        self.longPressGestureToInflate.delegate = self
        self.longPressGestureToInflate.minimumPressDuration = 0.1
        self.longPressGestureToInflate.addTarget(self, action: #selector(handleLongPressGestureToInflate(_:)))
    }
    
    @objc private func handleLongPressGestureToInflate(_ gesture: UILongPressGestureRecognizer) {
        guard let smallCardCollectionView = self.superview as? UICollectionView else { return }
        guard smallCardCollectionView.isEditing else { return }
        switch gesture.state {
            
        case .began:
            guard let smallCardCollectionView = self.superview as? UICollectionView else { return }
            guard smallCardCollectionView.isEditing else { return }
            
            self.inflateAnimator.addAnimations { [weak self] in
                guard let self else { return }
                self.transform = CGAffineTransform(scaleX: 1.07, y: 1.07)
            }
            self.inflateAnimator.addCompletion { [weak self] animatingPosition in
                guard let self else { return }
                gesture.state = .ended
                self.feedbackGenerator.impactOccurred()
                self.onLongPressSelected?()
            }
            
            self.inflateAnimator.startAnimation()
            
        default:
            self.inflateAnimator.stopAnimation(true)
            UIView.springAnimate(withDuration: 0.4) { [weak self] in
                self?.transform = .identity
            }
        }
    }
    
}


extension SmallCardCollectionViewCell: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer is UITapGestureRecognizer {
            return false
        } else {
            return true
        }
    }
    
}
