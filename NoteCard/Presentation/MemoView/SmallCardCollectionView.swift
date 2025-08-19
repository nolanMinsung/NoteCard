//
//  SmallCardCollectionView.swift
//  NoteCard
//
//  Created by 김민성 on 7/18/25.
//

import UIKit

import Wisp

final class SmallCardCollectionView: WispableCollectionView {
    
    private let smallCardSectionProvider: UICollectionViewCompositionalLayoutSectionProvider = { sectionIndex, layoutEnvironment in
        // 현재 컬렉션뷰의 너비 (또는 섹션의 컨테이너 너비)를 기반으로 셀 크기를 조정.
        let containerWidth = layoutEnvironment.container.contentSize.width
        
        // 가로 너비에 따라 컬럼 수를 동적으로 설정.
        let columns: Int
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            // 아이폰의 경우 column의 수를 3으로 고정
            columns = 3
        } else {
            switch containerWidth {
            case ..<500:
                columns = 1
            case 500..<700:
                columns = 2
            case 700..<1000:
                columns = 3
            default:
                columns = 4
            }
        }
        
        // setting item
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / CGFloat(columns)), // 부모 너비의 1/컬럼 수
            heightDimension: .fractionalHeight(1.0) // 그룹 높이와 동일
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5) // 셀 간의 간격
        
        
        // setting group
        let heightDimension: NSCollectionLayoutDimension = (
            (UIDevice.current.userInterfaceIdiom == .phone)
            ? .fractionalWidth(1.5 / CGFloat(columns))
            : .fractionalWidth(0.6 / CGFloat(columns))
        )
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0), // 섹션 너비 전체
            heightDimension: heightDimension // 그룹 높이 = 셀 높이
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        // setting section
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10) // 섹션 여백
        
        return section
    }
    
    init() {
        super.init(frame: .zero, sectionProvider: smallCardSectionProvider)
        
        layer.masksToBounds = false
        clipsToBounds = true
        allowsMultipleSelectionDuringEditing = true
        layer.cornerRadius = 13
        layer.cornerCurve = .continuous
        backgroundColor = .clear
        register(SmallCardCollectionViewCell.self,forCellWithReuseIdentifier: SmallCardCollectionViewCell.cellID)
        isScrollEnabled = true
        delaysContentTouches = false
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
