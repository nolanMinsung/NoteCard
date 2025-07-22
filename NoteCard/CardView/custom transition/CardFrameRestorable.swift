//
//  CardFrameRestorable.swift
//  NoteCard
//
//  Created by 김민성 on 7/21/25.
//

import UIKit


protocol CardFrameRestorable: UIViewController {
    
    func getFrameOfSelectedCell(indexPath: IndexPath) -> CGRect?
    
    func makeSelectedCellInvisible(indexPath: IndexPath)
    
    func makeSelectedCellVisible(indexPath: IndexPath)
    
}
