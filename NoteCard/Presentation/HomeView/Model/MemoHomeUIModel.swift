//
//  MemoHomeUIModel.swift
//  NoteCard
//
//  Created by 김민성 on 9/21/25.
//

import Foundation
import Domain
import DesignSystem
import Shared

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
