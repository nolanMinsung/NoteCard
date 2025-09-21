//
//  MemoHomeUIModel.swift
//  NoteCard
//
//  Created by 김민성 on 9/21/25.
//

import Foundation

struct MemoHomeUIModel: Hashable {
    
    enum Section: Hashable {
        case favorite
        case all
    }
    
    let memo: Memo
    let section: Section
    
    init(memo: Memo, section: Section) {
        self.memo = memo
        self.section = section
    }
    
}
