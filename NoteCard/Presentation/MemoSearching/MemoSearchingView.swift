//
//  MemoSearchingView.swift
//  NoteCard
//
//  Created by 김민성 on 8/6/25.
//

import UIKit

import Wisp

final class MemoSearchingView: UIView {
    
    let searchBar = SearchBar()
    private(set) var collectionView: WispableCollectionView!
    
    let sectionProvider: UICollectionViewCompositionalLayoutSectionProvider = { sectionIndex, environment in
        let containerWidth = environment.container.contentSize.width
        let columnCount: Int
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        if isPhone {
            columnCount = 1
        } else {
            switch containerWidth {
            case ..<500:
                columnCount = 1
            case 500..<700:
                columnCount = 2
            case 700..<1000:
                columnCount = 3
            default:
                columnCount = 4
            }
        }
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / CGFloat(columnCount)),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .init(top: 5, leading: 5, bottom: 5, trailing: 5)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: (columnCount == 1) ? .absolute(150) : .fractionalWidth(0.6 / CGFloat(columnCount))
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.contentInsets = .init(top: 0, leading: 5, bottom: 0, trailing: 5)
        let section = NSCollectionLayoutSection(group: group)
        return section
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .homeViewBackground
        
        searchBar.backgroundColor = .systemBackground
        
        let searchingLayout = UICollectionViewCompositionalLayout.wisp.make(sectionProvider: sectionProvider)
        collectionView = WispableCollectionView(frame: .zero, collectionViewLayout: searchingLayout)
        collectionView.backgroundColor = .clear
        collectionView.keyboardDismissMode = .onDrag
        collectionView.delaysContentTouches = false
        
        addSubview(collectionView)
        addSubview(searchBar)
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
        ])
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
