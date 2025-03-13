//
//  InsetTextField.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

final class InsetTextField: UITextField {
    
    
    var textInsets: UIEdgeInsets {
        didSet {
            setNeedsDisplay()
        }
    }
    
    
    //let categoryNameTextField: UITextField = {
    //    let textField = UITextField()
    //    textField.placeholder = "카테고리 이름 입력"
    //    textField.borderStyle = UITextField.BorderStyle.none
    //    textField.clipsToBounds = true
    //    textField.layer.cornerRadius = 10
    //    textField.backgroundColor = UIColor.white
    //    텍스트필드 글자의 왼쪽에 Inset 주기!!!
    //    textField.translatesAutoresizingMaskIntoConstraints = false
    //    return textField
    //}()
    
    
    init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        self.textInsets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        super.init(frame: CGRect.zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: self.textInsets)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: self.textInsets)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: self.textInsets)
    }
    
    
}

