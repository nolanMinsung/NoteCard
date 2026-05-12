//
//  CoreDataStack.swift
//  NoteCard
//
//  Created by 김민성 on 8/19/25.
//

import Combine
import Domain
import Shared
import CoreData
import Foundation

public final class CoreDataStack: ObservableObject {

    public static let shared = CoreDataStack()
    private init() { }

    // MARK: - Core Data stack

    public lazy var persistentContainer: NSPersistentContainer = {
        // Data 모듈로 옮긴 뒤 NSPersistentContainer(name:)은 Bundle.main에서 .momd를
        // 찾기 때문에 Data.framework 번들 안의 모델 파일을 못 찾고 빈 모델로 만들어진다.
        // 명시적으로 Bundle(for: Self.self)에서 모델 URL을 가져와 컨테이너에 주입한다.
        // mapping model(.cdm)도 같은 번들에 함께 존재해야 heavyweight migration이
        // NSMigrationManager에 의해 자동 검색된다 (Project.swift의 resources glob에
        // **/*.xcmappingmodel 포함됨).
        guard let modelURL = Bundle(for: CoreDataStack.self)
                .url(forResource: "NoteCardCoreData", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to locate NoteCardCoreData.momd in Data bundle.")
        }
        let container = NSPersistentContainer(name: "NoteCardCoreData", managedObjectModel: model)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    public private(set) lazy var backgroundContext = persistentContainer.newBackgroundContext()

    // MARK: - Core Data Saving support

    public func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}
