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
    
    let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = UIImageView.ContentMode.scaleAspectFit
        view.sizeToFit()
        view.image = UIImage(systemName: "photo")
//        view.backgroundColor = .systemOrange
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
//        view.clipsToBounds = true
//        view.layer.cornerRadius = 10
//        view.layer.cornerCurve = .continuous
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    
    lazy var scrollView: CardImageShowingScrollView = {
        let view = CardImageShowingScrollView(frame: .zero)
        
        view.addSubview(self.imageView)
        view.contentMode = .center
        view.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        view.backgroundColor = .clear
        view.clipsToBounds = false
        view.zoomScale = 1.0
        view.minimumZoomScale = 1.0
        view.maximumZoomScale = 5.0
        view.decelerationRate = .fast
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    
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
        
        configureHierarchy()
        setupUI()
        setupConstraints()
        setupDelegates()
        setupGestures()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        self.scrollView.zoomScale = 1.0
    }
    
    private func configureHierarchy() {
        self.contentView.addSubview(self.scrollView)
    }
    
    private func setupUI() {
        self.contentView.backgroundColor = .currentTheme.withAlphaComponent(0.1)
        self.contentView.clipsToBounds = true
        self.contentView.layer.cornerRadius = 5
        self.contentView.layer.cornerCurve = .continuous
    }
    
    private func setupConstraints() {
//        self.scrollView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0).isActive = true
//        self.scrollView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 0).isActive = true
//        self.scrollView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 0).isActive = true
//        self.scrollView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 0).isActive = true
        
        self.scrollViewCenterXConstraint.isActive = true
        self.scrollViewCenterYConstraint.isActive = true
        self.scrollViewWidthConstraint.isActive = true
        self.scrollViewHeightConstraint.isActive = true
        
//        self.imageView.topAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
//        self.imageView.leadingAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
//        self.imageView.trailingAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
//        self.imageView.bottomAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        
        
//        self.imageView.topAnchor.constraint(equalTo: self.scrollView.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
//        self.imageView.leadingAnchor.constraint(equalTo: self.scrollView.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
//        self.imageView.trailingAnchor.constraint(equalTo: self.scrollView.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
//        self.imageView.bottomAnchor.constraint(equalTo: self.scrollView.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        
//        self.imageView.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 0).isActive = true
//        self.imageView.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 0).isActive = true
//        self.imageView.trailingAnchor.constraint(equalTo: self.scrollView.trailingAnchor, constant: 0).isActive = true
//        self.imageView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor, constant: 0).isActive = true
        
//        self.imageView.topAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.topAnchor, constant: 0).isActive = true
//        self.imageView.leadingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.leadingAnchor, constant: 0).isActive = true
//        self.imageView.trailingAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.trailingAnchor, constant: 0).isActive = true
//        self.imageView.bottomAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.bottomAnchor, constant: 0).isActive = true
        
        
        self.imageViewCenterXConstraint.isActive = true
        self.imageViewCenterYConstraint.isActive = true
        self.imageViewWidthConstraint.isActive = true
        self.imageViewHeightConstraint.isActive = true
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
//        rectToZoom.size = CGSize(width: self.contentView.bounds.width / 2, height: self.contentView.bounds.height / 2)
        rectToZoom.size = CGSize(width: 100, height: 100)
        if self.scrollView.zoomScale > 1 {
            self.scrollView.setZoomScale(1.0, animated: true)
            
        } else {
//            self.scrollView.setZoomScale(2.0, animated: true)
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
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
    }
    
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    }
    
//    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        let imageRatio = self.imageView.image!.size.height / self.imageView.image!.size.width
//        let contentViewRatio = self.contentView.bounds.height / self.contentView.bounds.width
//        if imageRatio <= contentViewRatio {
//            let xOffset = scrollView.contentOffset.x
//            let yOffset = (self.imageView.frame.height - self.scrollView.frame.height) / 2
//            scrollView.setContentOffset(CGPoint(x: xOffset, y: yOffset), animated: true)
//        } else {
//            let xOffset = (self.imageView.frame.width - self.scrollView.frame.width) / 2
//            let yOffset = scrollView.contentOffset.y
//            scrollView.setContentOffset(CGPoint(x: xOffset, y: yOffset), animated: true)
//        }
//    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
    }
    
    
//    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
//        print(#function)
//        
//        let imageRatio = self.imageView.image!.size.height / self.imageView.image!.size.width
//        let contentViewRatio = self.contentView.bounds.height / self.contentView.bounds.width
//        if imageRatio <= contentViewRatio {
//            let xOffset = scrollView.contentOffset.x
//            let yOffset = (self.imageView.frame.height - self.scrollView.frame.height) / 2
//            scrollView.setContentOffset(CGPoint(x: xOffset, y: yOffset), animated: true)
//        } else {
//            let xOffset = (self.imageView.frame.width - self.scrollView.frame.width) / 2
//            let yOffset = scrollView.contentOffset.y
//            scrollView.setContentOffset(CGPoint(x: xOffset, y: yOffset), animated: true)
//            
//        }
//    }
    
}

