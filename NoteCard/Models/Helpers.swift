//
//  Helpers.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

//enum SectionName: String {
//    case section1 = "pencil"
//    case section2 = "eraser"
//    case section3 = "doc.plaintext"
//}


class NameContainer {
    
    static let shared = NameContainer()
    private init() {}
    
    private var vcTitleNameArray: [String] = ["카테고리", "넘기면서 보기", "목록 확인"]
    private var sectionNameArray: [String] = ["pencil", "page", "table view"]
    
    func getSectionNameArray() -> [String] {
        return self.sectionNameArray
    }
    
    func getVCTitleNameArray() -> [String] {
        return self.vcTitleNameArray
    }
    
    
}



