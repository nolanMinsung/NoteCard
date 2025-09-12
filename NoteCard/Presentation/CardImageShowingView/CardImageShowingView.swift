//
//  CardImageShowingView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

final class CardImageShowingView: UIView {
    
    let dismissButton = DismissButton()
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    private(set) var imageCollectionView: UICollectionView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUIProperties()
        configureHierarchy()
        setupConstraints()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUIProperties() {
        backgroundColor = .clear
        
        imageCollectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        // compositional layout에서 main axis의 scrolling 제한
        imageCollectionView.isScrollEnabled = false
        imageCollectionView.backgroundColor = .clear
        imageCollectionView.alpha = 0.0
        imageCollectionView.register(
            CardImageShowingCollectionViewCell.self,
            forCellWithReuseIdentifier: CardImageShowingCollectionViewCell.cellID
        )
    }
    
    private func configureHierarchy() {
        addSubview(blurView)
        addSubview(imageCollectionView)
        addSubview(dismissButton)
    }
    
    private func setupConstraints() {
        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
        ])
        
        imageCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageCollectionView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 40),
            imageCollectionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 0),
            imageCollectionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: 0),
            imageCollectionView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -130),
        ])
        
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dismissButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0),
            dismissButton.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -65),
            dismissButton.widthAnchor.constraint(equalToConstant: 60),
            dismissButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
    
}


private extension CardImageShowingView {
    
    func makeLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.9),
            heightDimension: .fractionalHeight(1.0)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPagingCentered
//        section.contentInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
        let compositionalLayout = UICollectionViewCompositionalLayout(section: section)
        return compositionalLayout
    }
    
}


extension CardImageShowingView {
    
    final class DismissButton: UIButton, ViewShrinkable {
        
        override var isHighlighted: Bool {
            didSet {
                if isHighlighted {
                    shrink(scale: 0.9)
                } else {
                    restore()
                }
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.setImage(UIImage(systemName: "xmark"), for: UIControl.State.normal)
            self.contentMode = .scaleAspectFit
            self.tintColor = .currentTheme
            self.backgroundColor = .systemBackground
            self.clipsToBounds = true
            self.alpha = 1
            self.layer.cornerRadius = 30
            self.layer.masksToBounds = false
            self.layer.shadowColor = UIColor.currentTheme.cgColor
            self.layer.shadowOffset = CGSize.zero
            self.layer.shadowRadius = 7
            self.layer.shadowOpacity = 0.3
            self.layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 60, height: 60), cornerRadius: 30).cgPath
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
}
