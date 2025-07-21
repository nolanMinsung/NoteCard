//
//  CardFrameRestorable.swift
//  NoteCard
//
//  Created by 김민성 on 7/21/25.
//

import UIKit


protocol CardFrameRestorable: UIViewController {
    
    func getFrameOfCell(indexPath: IndexPath) -> CGRect?
    
}
