//
//  UITextView+Combine.swift
//  NoteCard
//
//  Created by 김민성 on 10/26/25.
//

import Combine
import UIKit

extension UITextView {
    
    var textPublisher: AnyPublisher<String, Never> {
        let textChangePublisher = NotificationCenter.default
            .publisher(for: UITextView.textDidChangeNotification, object: self)
            .map { ($0.object as? UITextView)?.text ?? "" }
        
        return textChangePublisher
            .prepend(self.text ?? "")
            .eraseToAnyPublisher()
    }
    
}
