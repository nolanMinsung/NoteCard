//
//  HomeCollectionViewCategoryCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class HomeCollectionViewCategoryCell: UICollectionViewCell {
    
    static var cellID: String {
        return String(describing: self)
    }
    
    
    let longPressGesture = UILongPressGestureRecognizer()
    
    
    let labelCategoryName: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textAlignment = .center
        label.numberOfLines = 4
        label.textColor = UIColor.label
        label.backgroundColor = UIColor.clear
//        label.adjustsFontSizeToFitWidth = true
//        label.minimumScaleFactor = 0.8
        label.text = "임시 타이틀"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
    
    
    func setupUI() {
        self.contentView.backgroundColor = UIColor.memoBackground
        self.contentView.addSubview(labelCategoryName)
        
        self.contentView.clipsToBounds = true
        self.contentView.layer.cornerRadius = 25
        self.contentView.layer.cornerCurve = .continuous
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //self.layer.shadowOffset = CGSize(width: 5, height: 5)
        if self.contentView.traitCollection.userInterfaceStyle == .dark {
            self.layer.shadowPath = nil
            self.layer.shadowColor = nil
            
        } else {
//            let roundBezierPath = UIBezierPath(roundedRect: CGRect(x: 5, y: 5, width: 100, height: 100), cornerRadius: 28)
            let roundBezierPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 3, width: 100, height: 100), cornerRadius: 28)
            self.layer.shadowPath = roundBezierPath.cgPath
            self.layer.shadowOpacity = 0.2
            self.layer.shadowRadius = 5
            self.layer.shadowColor = UIColor.currentTheme().cgColor
            
        }
        
        
    }
    
    func setupConstraints() {
        labelCategoryName.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor, constant: 0).isActive = true
        labelCategoryName.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 0).isActive = true
//        labelCategoryName.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 5).isActive = true
        labelCategoryName.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 5).isActive = true
        labelCategoryName.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -5).isActive = true
//        labelCategoryName.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 5).isActive = true
    }
    
    
    private func setupDelegates() {
        self.longPressGesture.delegate = self
    }
    
    
    private func setupGesture() {
        self.longPressGesture.minimumPressDuration = 0.0
        self.longPressGesture.cancelsTouchesInView = false
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
                self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
            animator.startAnimation()
        }
    }
}


extension HomeCollectionViewCategoryCell: UIGestureRecognizerDelegate {
    
    //Cell에 longPressGesture를 추가하면 그 상위 뷰인 collection view 에 적용하는 다른 제스쳐가 안 먹힌다.
    //여기서 말하는 '다른 제스쳐' 란, collection view를 스크롤 하는 행위를 말한다. (그럼 scroll 이 gestureRecognizer란 말이냐?!! 그렇다!!)
    //추측컨데, 아마 UICollectionView의 scroll도 내부적으로 UIPanGesture로 인식해서 처리하나봄...
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

