////
////  ShadowView.swift
////  CardMemo
////
////  Created by 김민성 on 2023/11/22.
////
//
//import UIKit
//
//final class UIShadowView: UIView {
//    
//    var shadowPath: CGPath!
//    var shadowOffset: CGSize!
//    var shadowColor: CGColor!
//    var shadowOpacity: Float!
//    var shadowRadius: CGFloat!
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    init(shadowOffset: CGSize? = CGSize(width: 0, height: 0),
//         shadowColor: CGColor? = UIColor.black.cgColor,
//         shadowOpacity: Float? = 1,
//         shadowRadius: CGFloat? = 3) {
//        
//        
//        //self.shadowPath = shadowPath
//        self.shadowOffset = shadowOffset
//        self.shadowColor = shadowColor
//        self.shadowOpacity = shadowOpacity
//        self.shadowRadius = shadowRadius
//        
//        super.init(frame: .zero)
//    }
//    
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        
//        let bezierPath: UIBezierPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 5)
//        self.shadowPath = bezierPath.cgPath
//        
//        self.layer.shadowPath = self.shadowPath
//        self.layer.shadowOffset = self.shadowOffset
//        self.layer.shadowColor = self.shadowColor
//        self.layer.shadowOpacity = self.shadowOpacity
//        self.layer.shadowRadius = self.shadowRadius
//    }
//    
//    
//    
//    
//}
