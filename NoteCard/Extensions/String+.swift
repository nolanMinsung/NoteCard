//
//  String+.swift
//  NoteCard
//
//  Created by 김민성 on 7/18/25.
//

import Foundation


extension String {
    
    func localized(value: String = "localized 필요", comment: String = "") -> String {
        return NSLocalizedString(self, value: "", comment: "")
    }
    
}
