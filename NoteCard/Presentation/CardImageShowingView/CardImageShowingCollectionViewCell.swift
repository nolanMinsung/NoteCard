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
    
    lazy var scrollViewCenterXConstraint = scrollView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 0)
    lazy var scrollViewCenterYConstraint = scrollView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0)
    lazy var scrollViewWidthConstraint = scrollView.widthAnchor.constraint(equalToConstant: contentView.bounds.width)
    lazy var scrollViewHeightConstraint = scrollView.heightAnchor.constraint(equalToConstant: contentView.bounds.height)
    
    lazy var imageViewCenterXConstraint = imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor, constant: 0)
    lazy var imageViewCenterYConstraint = imageView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor, constant: 0)
    lazy var imageViewWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: contentView.bounds.width)
    lazy var imageViewHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: contentView.bounds.height)
    
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
        scrollView.delegate = self
    }
    
    private func setupGestures() {
        imageView.addGestureRecognizer(self.doubleTapGesture)
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.addTarget(self, action: #selector(handleDoubleTapGesture))
    }
    
    @objc private func handleDoubleTapGesture(gesture: UITapGestureRecognizer) {
        print(#function)
        let touchPoint = gesture.location(ofTouch: 0, in: imageView)
        let imageFrame = imageView.frame
        print(imageFrame)
        print(touchPoint)
        
        let location = gesture.location(in: self.scrollView)
        var rectToZoom = CGRect()
        rectToZoom.origin = CGPoint(x: location.x - 50, y: location.y - 50)
        rectToZoom.size = CGSize(width: 100, height: 100)
        if scrollView.zoomScale > 1 {
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            scrollView.zoom(to: rectToZoom, animated: true)
        }
    }
    
    func configureCell(with image: UIImage) {
        imageView.image = image
        let contentViewRatio = self.contentView.bounds.height / self.contentView.bounds.width
        let imageSizeRatio = image.size.height / image.size.width
        
        if imageSizeRatio <= contentViewRatio {
            scrollViewWidthConstraint.constant = contentView.bounds.width
            imageViewWidthConstraint.constant = contentView.bounds.width
            
            scrollViewHeightConstraint.constant = contentView.bounds.width * imageSizeRatio
            imageViewHeightConstraint.constant = contentView.bounds.width * imageSizeRatio
        } else {
            scrollViewHeightConstraint.constant = contentView.bounds.height
            imageViewHeightConstraint.constant = contentView.bounds.height
            
            scrollViewWidthConstraint.constant = contentView.bounds.height / imageSizeRatio
            imageViewWidthConstraint.constant = contentView.bounds.height / imageSizeRatio
        }
        updateConstraints()
    }
}


extension CardImageShowingCollectionViewCell: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
}

