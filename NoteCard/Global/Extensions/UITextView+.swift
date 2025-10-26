//
//  UITextView+.swift
//  NoteCard
//
//  Created by 김민성 on 7/18/25.
//

import UIKit


extension UITextView {
    
    /// UITextView에 행간을 적용한 텍스트를 입력하는 메서드
    /// - Parameters:
    ///   - textString: 입력할 텍스트
    ///   - lineSpace: 텍스트의 행간. CGFloat 타입
    ///   - font: 텍스트의 폰트. UIFont 타입
    ///   - color: 텍스트의 색깔(foregroundColor). UIColo? 타입이며, nil일 경우 UIColor.black 할당)
    func setLineSpace(with textString: String, lineSpace: CGFloat, font: UIFont, textColor: UIColor? = .label) {
        
        //NSAttributedString.Key 중에는 paragraphStyle이라는 게 있는데, 이는 text 의 여러 줄에 걸쳐서 적용되는 글의 속성을 뜻하는 듯.
        //이 paragraphStyle을 잘 설정해서 글의 좌우정렬, 행간, 들여쓰기 등을 설정할 수 있다.
        //여기서는 행간을 설정해야 하므로 paragraphStyle에 행간만 설정해 주었음.
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.lineBreakStrategy = .hangulWordPriority
        mutableParagraphStyle.lineSpacing = lineSpace
        mutableParagraphStyle.paragraphSpacing = 0
        let attributes = [
            NSAttributedString.Key.paragraphStyle: mutableParagraphStyle,
            .font: font,
            .foregroundColor: textColor!
        ]
        self.typingAttributes = attributes
        self.attributedText = NSAttributedString(string: textString, attributes: attributes)
    }
}
