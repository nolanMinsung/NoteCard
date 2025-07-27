//
//  WispPresentable.swift
//  NoteCard
//
//  Created by 김민성 on 7/27/25.
//

import UIKit


protocol WispPresentable: UIViewController {
    
    func wispableCollectionView() -> WispableCollectionView
    
}


