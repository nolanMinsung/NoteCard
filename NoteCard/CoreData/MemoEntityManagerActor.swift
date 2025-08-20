//
//  MemoEntityManagerActor.swift
//  NoteCard
//
//  Created by 김민성 on 8/20/25.
//

import CoreData
import Foundation

@globalActor
actor MemoEntityActor {
    static let shared = MemoEntityActor()
}


@MemoEntityActor
final class MemoEntityActorManager {
    
    static let shared = MemoEntityActorManager()
    private init() { }
    
    private var entityName: String { return "MemoEntity" }
    
    private var context: NSManagedObjectContext {
        CoreDataStack.shared.persistentContainer.viewContext
    }
    
}
