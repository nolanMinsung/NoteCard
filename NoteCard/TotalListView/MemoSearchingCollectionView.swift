//
//  MemoSearchingCollectionView.swift
//  NoteCard
//
//  Created by 김민성 on 2024/02/12.
//

import UIKit

class MemoSearchingCollectionView: UICollectionView {
    
    let characterSearchingImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "characterSearchingImage"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        
        configureHierarchy()
        setupConstraints()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureHierarchy() {
        self.addSubview(characterSearchingImageView)
    }
    
    func showImage() {
        self.characterSearchingImageView.isHidden = false
    }
    
    func hideImage() {
        self.characterSearchingImageView.isHidden = true
    }
    
    private func setupConstraints() {
        self.characterSearchingImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
//        self.characterSearchingImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        self.characterSearchingImageView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: SizeContainer.screenSize.height * 0.15).isActive = true
//        self.characterSearchingImageView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        self.characterSearchingImageView.widthAnchor.constraint(equalToConstant: SizeContainer.screenSize.width * 0.5).isActive = true
        self.characterSearchingImageView.heightAnchor.constraint(equalToConstant: SizeContainer.screenSize.width * 0.5).isActive = true
    }
    
}
