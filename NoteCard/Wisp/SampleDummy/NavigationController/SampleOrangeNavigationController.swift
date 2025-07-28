//
//  SampleOrangeNavigationController.swift
//  NoteCard
//
//  Created by 김민성 on 7/28/25.
//

import UIKit

class SampleOrangeNavigationController: UINavigationController, WispDismissable {
    
    var viewInset: NSDirectionalEdgeInsets
    
    init(viewInset: NSDirectionalEdgeInsets) {
        self.viewInset = viewInset
        super.init(rootViewController: OrangeViewController())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
