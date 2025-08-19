//
//  MemoEntity+CoreDataClass.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//
//

import Foundation
import CoreData

@objc(MemoEntity)
public class MemoEntity: NSManagedObject {
    
    static let memoManager = MemoEntityManager.shared
    static var numberOfMemos: Int {
        let array = memoManager.getMemoEntitiesFromCoreData()
        return array.count
    }
    
}
