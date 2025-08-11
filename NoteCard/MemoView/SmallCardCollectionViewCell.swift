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
    
    let selectionAnimator = UIViewPropertyAnimator(duration: 0.2, curve: UIView.AnimationCurve.easeOut)
    let deselectionAnimator = UIViewPropertyAnimator(duration: 0.2, curve: UIView.AnimationCurve.easeOut)
    
    var gestureInitialLocation: CGPoint!
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                UIView.springAnimate(withDuration: 0.3) { [weak self] in
                    self?.transform = .init(scaleX: 0.95, y: 0.95)
                }
            } else {
                UIView.springAnimate(withDuration: 0.3) { [weak self] in
                    self?.transform = .identity
                }
            }
        }
    }
    
//    override var isSelected: Bool {
//        didSet {
//            switch isSelected {
//            case true:
//
//                self.selectionAnimator.addAnimations {
//                    self.layer.borderColor = UIColor.currentTheme.cgColor
//                    self.layer.borderWidth = 2
//                    self.opaqueView.alpha = 0.0
//                }
//                
//                self.deselectionAnimator.stopAnimation(true)
//                self.selectionAnimator.startAnimation()
//                
//            case false:
//                
//                self.deselectionAnimator.addAnimations {
//                    self.layer.borderWidth = 0
//                    self.opaqueView.alpha = 0.7
//                }
//                
//                self.selectionAnimator.stopAnimation(true)
//                self.deselectionAnimator.startAnimation()
//            }
//        }
//    }
    
    let memoManager = MemoEntityManager.shared
    let inflateAnimator = UIViewPropertyAnimator(duration: 0.4, controlPoint1: CGPoint(x: 0.2, y: 0.5), controlPoint2: CGPoint(x: 0.2, y: 0.6))
    let cancelInflateAnimator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1)
    var longPressGestureToSelect = UILongPressGestureRecognizer()
    var longPressGestureToInflate = UILongPressGestureRecognizer()
    var memoEntity: MemoEntity?
    var cellFrame: CGRect!
    
    var indexPath: IndexPath {
        guard let smallCardCollectionView = self.superview as? UICollectionView else { fatalError() }
        guard let returnValue = smallCardCollectionView.indexPath(for: self) else { fatalError() }
        return returnValue
    }
    
//    weak var delegate: LargeCardCollectionViewCellDelegate?
    
    let opaqueView: UIView = {
        let view = UIView()
        view.backgroundColor = .memoCellOpaqueView
        view.alpha = 0
        view.clipsToBounds = true
        view.layer.cornerRadius = 13
        view.layer.cornerCurve = .continuous
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var titleTextField: UITextField = {
        let textField = UITextField()
        textField.isEnabled = false
        textField.borderStyle = .none
        textField.placeholder = "제목 없음".localized()
        textField.font = UIFont.systemFont(ofSize: 15)
        textField.textColor = .label
        textField.textAlignment = .center
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    let textViewMemo: UITextView = {
        let textView = UITextView()
        //textView.font = UIFont.systemFont(ofSize: 12)
        textView.textAlignment = .left
        textView.clipsToBounds = true
        textView.backgroundColor = .clear
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
        
        switch smallCardCollectionView.isEditing {
        case true:
            self.longPressGestureToSelect.isEnabled = false
            self.longPressGestureToInflate.isEnabled = true
        case false:
            self.longPressGestureToSelect.isEnabled = true
            self.longPressGestureToInflate.isEnabled = false
        }
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func setupUI() {
        //cell의 contentView의 backgroundColor 대신에 cell의 backgroundColor에 직접 색을 넣어주는 이유는
        //팝업카드가 올라왔을 때 다크모드가 바뀌어도 셀 스냅샷의 배경을 투명하게 함으로써 최대한 덜 어색하게 보이게 하기 위함
        self.backgroundColor = UIColor.memoBackground
        self.clipsToBounds = true
        self.layer.masksToBounds = false
        self.layer.cornerRadius = 13
        self.layer.cornerCurve = .continuous
        
        self.contentView.addSubview(self.titleTextField)
        self.contentView.addSubview(self.textViewMemo)
        self.contentView.addSubview(self.opaqueView)
        self.titleTextField.frame.size = self.titleTextField.intrinsicContentSize
    }
    
    func configureCell(with memo: MemoEntity) {
        self.memoEntity = memo
        self.titleTextField.text = memo.memoTitle
        self.textViewMemo.text = memo.memoText
        self.textViewMemo.setLineSpace(with: memo.memoText, lineSpace: 2, font: UIFont.systemFont(ofSize: 12))
    }
    
    func setConstraints() {
        self.titleTextField.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 5).isActive = true
        self.titleTextField.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 5).isActive = true
        self.titleTextField.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -5).isActive = true
        self.titleTextField.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        self.textViewMemo.topAnchor.constraint(equalTo: self.titleTextField.bottomAnchor, constant: 5).isActive = true
        self.textViewMemo.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 5).isActive = true
        self.textViewMemo.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -5).isActive = true
        self.textViewMemo.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -5).isActive = true
        
        self.opaqueView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0).isActive = true
        self.opaqueView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 0).isActive = true
        self.opaqueView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 0).isActive = true
        self.opaqueView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 0).isActive = true
    }
    
    private func setupGesture() {
//        self.contentView.addGestureRecognizer(self.longPressGestureToSelect)
//        self.contentView.addGestureRecognizer(self.longPressGestureToInflate)
        
        self.longPressGestureToSelect.delegate = self
        self.longPressGestureToSelect.minimumPressDuration = 0.0
        self.longPressGestureToSelect.addTarget(self, action: #selector(handleLongPressGestureToSelect(_:)))
        
        self.longPressGestureToInflate.delegate = self
        self.longPressGestureToInflate.minimumPressDuration = 0.1
        self.longPressGestureToInflate.addTarget(self, action: #selector(handleLongPressGestureToInflate(_:)))
    }
    
    @objc private func handleLongPressGestureToSelect(_ gesture: UILongPressGestureRecognizer) {
        
        guard let smallCardCollectionView = self.superview as? UICollectionView else { return }
        guard !smallCardCollectionView.isEditing else { return }
        
        switch gesture.state {
        case .began:
            let animator = UIViewPropertyAnimator(duration: 0.6, controlPoint1: CGPoint(x: 0.15, y: 1), controlPoint2: CGPoint(x: 0.25, y: 1.0))
            animator.addAnimations {
                self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
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
            }
            animator.startAnimation()
            
            guard let memoEntity else { return }
            
//            self.delegate?.triggerPresentMethod(
//                presented: PopupCardViewController(
//                    memo: memoEntity,
//                    indexPath: self.indexPath,
//                ),
//                animated: true
//            )
            
        default:
            let animator = UIViewPropertyAnimator(duration: 0.2, curve: UIView.AnimationCurve.easeInOut)
            animator.addAnimations {
                self.transform = CGAffineTransform.identity
            }
            animator.startAnimation()
        }
        
    }
    
    @objc private func handleLongPressGestureToInflate(_ gesture: UILongPressGestureRecognizer) {
        guard let smallCardCollectionView = self.superview as? UICollectionView else { return }
        guard smallCardCollectionView.isEditing else { return }
            switch gesture.state {
                
            case .began:
                guard let smallCardCollectionView = self.superview as? UICollectionView else { return }
                guard smallCardCollectionView.isEditing else { return }
                self.gestureInitialLocation = gesture.location(in: self.contentView)
                self.inflateAnimator.addAnimations { [weak self] in
                    guard let self else { return }
                    
                    self.transform = CGAffineTransform(scaleX: 1.07, y: 1.07)
                }
                self.inflateAnimator.addCompletion { [weak self] animatingPosition in
                    guard let self else { return }
                    guard let memoEntity else { return }
                    
//                    self.delegate?.triggerPresentMethod(
//                        presented: PopupCardViewController(memo: memoEntity,indexPath: self.indexPath,),
//                        animated: true
//                    )
                }
                
                self.inflateAnimator.startAnimation()
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + self.inflateAnimator.duration * 0.8) { [weak self] in
                    guard let self else { fatalError() }
                    if self.inflateAnimator.isRunning {
                        NotificationCenter.default.post(Notification(name: Notification.Name("feedbackGeneratorNotification")))
                    }
                }
                
            case .changed:
                //            if self.inflateAnimator.fractionComplete > 0.5 {
                let gestureCurrentLocation = gesture.location(in: self.contentView)
                if hypot(gestureCurrentLocation.x - gestureInitialLocation.x, gestureCurrentLocation.y - gestureInitialLocation.y) > 7 {
                    self.inflateAnimator.stopAnimation(true)
                    self.cancelInflateAnimator.addAnimations {
                        self.transform = CGAffineTransform.identity
                    }
                    self.cancelInflateAnimator.startAnimation()
                }
                
                
            case .ended:
                fallthrough
                
            case .cancelled:
                self.inflateAnimator.stopAnimation(true)
                self.cancelInflateAnimator.addAnimations {
                    self.transform = CGAffineTransform.identity
                }
                self.cancelInflateAnimator.startAnimation()
                
            default:
                self.inflateAnimator.stopAnimation(true)
                self.cancelInflateAnimator.addAnimations {
                    self.transform = CGAffineTransform.identity
                }
                self.cancelInflateAnimator.startAnimation()
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
