//
//  CardImageShowingCollectionViewCell.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class CardImageShowingCollectionViewCell: UICollectionViewCell {
    
    static var cellID: String {
        return String(describing: self)
    }
    
    let doubleTapGesture = UITapGestureRecognizer()
    
    private let imageView = UIImageView()
    private let scrollView = CardImageShowingScrollView()
    
    lazy var scrollViewCenterXConstraint = self.scrollView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor, constant: 0)
    lazy var scrollViewCenterYConstraint = self.scrollView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: 0)
    lazy var scrollViewWidthConstraint = self.scrollView.widthAnchor.constraint(equalToConstant: self.contentView.bounds.width)
    lazy var scrollViewHeightConstraint = self.scrollView.heightAnchor.constraint(equalToConstant: self.contentView.bounds.height)
    
    lazy var imageViewCenterXConstraint = self.imageView.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor, constant: 0)
    lazy var imageViewCenterYConstraint = self.imageView.centerYAnchor.constraint(equalTo: self.scrollView.centerYAnchor, constant: 0)
    lazy var imageViewWidthConstraint = self.imageView.widthAnchor.constraint(equalToConstant: self.contentView.bounds.width)
    lazy var imageViewHeightConstraint = self.imageView.heightAnchor.constraint(equalToConstant: self.contentView.bounds.height)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUIProperties()
        configureHierarchy()
        setupConstraints()
        setupDelegates()
        setupGestures()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        scrollView.setZoomScale(1.0, animated: false)
    }
    
    private func configureHierarchy() {
        contentView.addSubview(scrollView)
        scrollView.addSubview(imageView)
    }
    
    private func setupUIProperties() {
        contentView.backgroundColor = .currentTheme.withAlphaComponent(0.1)
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 5
        contentView.layer.cornerCurve = .continuous
        
        imageView.contentMode = UIImageView.ContentMode.scaleAspectFit
        imageView.sizeToFit()
        imageView.image = UIImage(systemName: "photo")
        imageView.backgroundColor = .clear
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.contentMode = .center
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        scrollView.backgroundColor = .clear
        scrollView.clipsToBounds = false
        scrollView.zoomScale = 1.0
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.decelerationRate = .fast
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConstraints() {
        scrollViewCenterXConstraint.isActive = true
        scrollViewCenterYConstraint.isActive = true
        scrollViewWidthConstraint.isActive = true
        scrollViewHeightConstraint.isActive = true
        
        imageViewCenterXConstraint.isActive = true
        imageViewCenterYConstraint.isActive = true
        imageViewWidthConstraint.isActive = true
        imageViewHeightConstraint.isActive = true
    }
    
    private func setupDelegates() {
        self.scrollView.delegate = self
    }
    
    private func setupGestures() {
        self.imageView.addGestureRecognizer(self.doubleTapGesture)
        self.doubleTapGesture.numberOfTapsRequired = 2
        self.doubleTapGesture.addTarget(self, action: #selector(handleDoubleTapGesture))
    }
    
    @objc private func handleDoubleTapGesture(gesture: UITapGestureRecognizer) {
        print(#function)
        let touchPoint = gesture.location(ofTouch: 0, in: self.imageView)
        let imageFrame = self.imageView.frame
        print(imageFrame)
        print(touchPoint)
        
        let location = gesture.location(in: self.scrollView)
        var rectToZoom = CGRect()
        rectToZoom.origin = CGPoint(x: location.x - 50, y: location.y - 50)
        rectToZoom.size = CGSize(width: 100, height: 100)
        if self.scrollView.zoomScale > 1 {
            self.scrollView.setZoomScale(1.0, animated: true)
        } else {
            self.scrollView.zoom(to: rectToZoom, animated: true)
        }
    }
    
    func configureCell(with image: UIImage) {
        self.imageView.image = image
        let contentViewRatio = self.contentView.bounds.height / self.contentView.bounds.width
        let imageSizeRatio = image.size.height / image.size.width
        
        if imageSizeRatio <= contentViewRatio {
            self.scrollViewWidthConstraint.constant = self.contentView.bounds.width
            self.imageViewWidthConstraint.constant = self.contentView.bounds.width
            
            self.scrollViewHeightConstraint.constant = self.contentView.bounds.width * imageSizeRatio
            self.imageViewHeightConstraint.constant = self.contentView.bounds.width * imageSizeRatio
        } else {
            self.scrollViewHeightConstraint.constant = self.contentView.bounds.height
            self.imageViewHeightConstraint.constant = self.contentView.bounds.height
            
            self.scrollViewWidthConstraint.constant = self.contentView.bounds.height / imageSizeRatio
            self.imageViewWidthConstraint.constant = self.contentView.bounds.height / imageSizeRatio
        }
        updateConstraints()
    }
}


extension CardImageShowingCollectionViewCell: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
}

