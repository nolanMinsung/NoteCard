//
//  WispCompositionalLayout.swift
//  NoteCard
//
//  Created by 김민성 on 7/26/25.
//

import UIKit

internal protocol CustomCompositionalLayoutDelegate: AnyObject {
    
    func layoutInvalidated()
    
}


class CustomCompositionalLayout: UICollectionViewCompositionalLayout {

    weak var delegate: (any CustomCompositionalLayoutDelegate)?
    
    override init(sectionProvider: @escaping UICollectionViewCompositionalLayoutSectionProvider) {
        
        /// - NOTE: 사용자가 제공한 `sectionProvider`를 재정의하여 사용.
        /// 모든 `section`의 `visibleItemsInvalidationHandler`가 `nil`이면
        /// compositional layout의 main axis의 스크롤 시에는 `delegate` 함수가 호출되지 않음.
        /// `visibleItemsInvalidationHandler`에 명시적으로 클로저를 할당하여 모든 방향의 스크롤시 `delegate`  메서드 호출하도록 구현함.
        super.init(sectionProvider: { sectionIndex, layoutEnvironment in
            guard let section = sectionProvider(sectionIndex, layoutEnvironment) else { return nil }
            let originalHandler = section.visibleItemsInvalidationHandler
            section.visibleItemsInvalidationHandler = { visibleItems, contentOffset, environment in
                originalHandler?(visibleItems, contentOffset, environment)
            }
            return section
        })
    }

    override init(section: NSCollectionLayoutSection) {
        let originalHandler = section.visibleItemsInvalidationHandler
        section.visibleItemsInvalidationHandler = { visibleItems, contentOffset, environment in
            originalHandler?(visibleItems, contentOffset, environment)
        }
        
        /// - NOTE: 사용자가 제공한 `NSCollectionLayoutSection` 인스턴스의 `visibleItemsInvalidationHandler`가 `nil`이면
        /// compositional layout의 main axis의 스크롤 시에는 `delegate` 함수가 호출되지 않음.
        /// `visibleItemsInvalidationHandler`에 명시적으로 클로저를 할당하여 모든 방향의 스크롤시 `delegate`  메서드 호출하도록 구현함.
        super.init(section: section)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // 레이아웃이 무효화될 때마다 호출되는 메서드를 오버라이드합니다.
    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        super.invalidateLayout(with: context)
        
        delegate?.layoutInvalidated()
    }
    
}



