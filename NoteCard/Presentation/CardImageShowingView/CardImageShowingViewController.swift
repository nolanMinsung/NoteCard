//
//  CardImageShowingViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class CardImageShowingViewController: UIViewController {
    
    private let initialIndexPath: IndexPath
    private var imageArray: [UIImage] = []
    
    private let rootView = CardImageShowingView()
    
    init(indexPath: IndexPath, images: [UIImage]) {
        self.initialIndexPath = indexPath
        self.imageArray = images
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = rootView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDelegates()
        rootView.dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        rootView.imageCollectionView.scrollToItem(at: initialIndexPath, at: .centeredHorizontally, animated: false)
        rootView.imageCollectionView.alpha = 1.0
    }
    
    private func setupDelegates() {
        rootView.imageCollectionView.dataSource = self
    }
    
    @objc private func dismissButtonTapped() {
        dismiss(animated: true)
    }
    
}


// MARK: - UICollectionViewDataSource
extension CardImageShowingViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.rootView.imageCollectionView.dequeueReusableCell(
            withReuseIdentifier: CardImageShowingCollectionViewCell.cellID,
            for: indexPath
        ) as! CardImageShowingCollectionViewCell
        cell.configureCell(with: imageArray[indexPath.item])
        
        return cell
    }
    
}
