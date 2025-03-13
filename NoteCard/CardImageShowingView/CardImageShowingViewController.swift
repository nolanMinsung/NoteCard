//
//  CardImageShowingViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class CardImageShowingViewController: UIViewController {
    
    let initialIndexPath: IndexPath
    let longPressGesture = UILongPressGestureRecognizer()
    let imageEntitiesArray: [ImageEntity]
    var thumbnailArray: [UIImage] = []
    var imageArray: [UIImage] = []
    
    lazy var cardImageShowingView = self.view as! CardImageShowingView
    lazy var dismissButton = cardImageShowingView.dismissButton
    lazy var cardImageShowingCollectionView = self.cardImageShowingView.cardImageShowingCollectionView
    
    let buttonShrinkAnimator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1)
    let buttonEnlargeAnimator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1)
    
//    var interactionController: CardImageShowingInteractionController?
    
    init(indexPath: IndexPath, imageEntitiesArray: [ImageEntity]) {
        self.initialIndexPath = indexPath
        self.imageEntitiesArray = imageEntitiesArray
        
        super.init(nibName: nil, bundle: nil)
        
        imageEntitiesArray.forEach { [weak self] imageEntity in
            guard let self else { fatalError() }
            guard let thumbnail = ImageEntityManager.shared.getThumbnailImage(imageEntity: imageEntity) else { fatalError() }
            guard let image = ImageEntityManager.shared.getImage(imageEntity: imageEntity) else { fatalError() }
            
            self.thumbnailArray.append(thumbnail)
            self.imageArray.append(image)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func loadView() {
        self.view = CardImageShowingView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDelegates()
        setupGestures()
        setupButtonsAction()
//        self.interactionController = CardImageShowingInteractionController(cardImageShowingVC: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.cardImageShowingCollectionView.alpha = 0
        
        let animator = UIViewPropertyAnimator(duration: 0.2, dampingRatio: 1)
        animator.addAnimations { [weak self] in
            guard let self else { fatalError() }
            self.cardImageShowingCollectionView.alpha = 1
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { fatalError() }
            self.cardImageShowingCollectionView.scrollToItem(at: self.initialIndexPath, at: .left, animated: false)
            animator.startAnimation()
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
//        self.cardImageShowingCollectionView.scrollToItem(at: self.initialIndexPath, at: UICollectionView.ScrollPosition(), animated: true)
    }
    
    private func setupDelegates() {
        self.cardImageShowingCollectionView.dataSource = self
        self.cardImageShowingCollectionView.delegate = self
    }
    
    private func setupGestures() {
        self.longPressGesture.minimumPressDuration = 0
        self.longPressGesture.addTarget(self, action: #selector(handleLongPressGesture(gesture:)))
    }
    
    @objc private func handleLongPressGesture(gesture: UILongPressGestureRecognizer) {
        print(#function)
        
        switch gesture.state {
            
        case .began:
            
            self.buttonShrinkAnimator.addAnimations { [weak self] in
                guard let self else { fatalError() }
                self.dismissButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            }
            self.buttonShrinkAnimator.startAnimation()
            
        case .changed:
            
            self.buttonEnlargeAnimator.addAnimations { [weak self] in
                guard let self else { fatalError() }
                self.dismissButton.transform = CGAffineTransform.identity
            }
            
            if !self.dismissButton.bounds.contains(gesture.location(in: self.dismissButton)) {
                self.buttonShrinkAnimator.stopAnimation(true)
                gesture.isEnabled = false
                gesture.isEnabled = true
                self.buttonEnlargeAnimator.startAnimation()
            }
            
            
        case .ended:
            
            self.buttonEnlargeAnimator.addAnimations { [weak self] in
                guard let self else { fatalError() }
                self.dismissButton.transform = CGAffineTransform.identity
            }
            self.buttonEnlargeAnimator.startAnimation()
            
            if self.dismissButton.bounds.contains(gesture.location(in: self.dismissButton)) {
                self.dismiss(animated: true)
            }
            
            
        default:
            
            self.buttonEnlargeAnimator.addAnimations { [weak self] in
                guard let self else { fatalError() }
                self.dismissButton.transform = CGAffineTransform.identity
            }
            self.buttonEnlargeAnimator.startAnimation()
            
        }
        
    }
    
    private func setupButtonsAction() {
        self.dismissButton.addGestureRecognizer(self.longPressGesture)
    }
    
}



extension CardImageShowingViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let imageCount = self.imageArray.count
        return imageCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.cardImageShowingCollectionView.dequeueReusableCell(withReuseIdentifier: CardImageShowingCollectionViewCell.cellID, for: indexPath) as! CardImageShowingCollectionViewCell
        cell.configureCell(with: self.thumbnailArray[indexPath.row])
        DispatchQueue.main.async { [weak self, weak cell] in
            guard let self else { fatalError() }
            guard let cell else { return }
            
            cell.configureCell(with: self.imageArray[indexPath.row])
        }
        
        return cell
    }
    
}

extension CardImageShowingViewController: UICollectionViewDelegate {
    
}




extension CardImageShowingViewController: UICollectionViewDelegateFlowLayout {
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView == self.cardImageShowingCollectionView else { return }
        guard let screenSize = UIScreen.current?.bounds.size else { fatalError() }
        
        let currentIndex = ((scrollView.contentOffset.x + scrollView.contentInset.left) / (screenSize.width * 0.9 + 10)).rounded()
        print("currentIndex는 \(currentIndex)")
        let targetCardIndex = (((targetContentOffset.pointee.x + screenSize.width * 0.05 /*left inset*/ ) / (screenSize.width * 0.9 + 10) + 0.5) / 1).rounded(FloatingPointRoundingRule.down)
        print("targetCardIndex :", targetCardIndex)
        print("velocity.x :", velocity.x)
//        targetContentOffset.pointee = CGPoint(x: index * cellWidth - scrollView.contentInset.left, y: scrollView.contentInset.top)
        
        if velocity.x < 0 {
            targetContentOffset.pointee.x = -(scrollView.contentInset.left) + ((screenSize.width * 0.9 + 10) * (currentIndex - 1))
        } else if velocity.x > 0 {
            targetContentOffset.pointee.x = -(scrollView.contentInset.left) + ((screenSize.width * 0.9 + 10) * (currentIndex + 1))
        } else {
            targetContentOffset.pointee.x = -(screenSize.width * 0.05) + ((screenSize.width * 0.9 + 10) * currentIndex)
        }
    }
    
}
