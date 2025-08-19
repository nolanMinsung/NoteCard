//
//  AppDelegate.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit
import CoreData

@main

class AppDelegate: UIResponder, UIApplicationDelegate {

    
    var memoMakingVC: MemoMakingViewController? = nil
    var memoEditingVC: MemoEditingViewController? = nil
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        
        // 앱 내의 설정값들 초기화 (다크모드 제외) -> 다크모드는 window 를 바꿔야 해서, window 설정하는 SceneDelegate에서...
        
        // 현재는 날짜 표시 형식을 직접 UserDefault에 저장하지 않고, locale을 기반으로 자동으로 변경되도록 설정.
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.dateFormat.rawValue)
//        if UserDefaults.standard.string(forKey: KeysForUserDefaults.dateFormat.rawValue) == nil {
//            UserDefaults.standard.setValue("yyyy. M. d. (EEE)", forKey: KeysForUserDefaults.dateFormat.rawValue)
//        }
        
        // 24시간제 표시 여부 초기화
        if UserDefaults.standard.string(forKey: UserDefaultsKeys.isTimeFormat24.rawValue) == nil {
            UserDefaults.standard.setValue(true, forKey: UserDefaultsKeys.isTimeFormat24.rawValue)
        }
        
        // locale 초기화
        if UserDefaults.standard.string(forKey: UserDefaultsKeys.locale.rawValue) == nil {
            UserDefaults.standard.setValue("ko_KR", forKey: UserDefaultsKeys.locale.rawValue)
        }
        
        // 정렬 기준 초기화
        if UserDefaults.standard.string(forKey: UserDefaultsKeys.orderCriterion.rawValue) == nil {
            UserDefaults.standard.setValue(OrderCriterion.modificationDate.rawValue, forKey: UserDefaultsKeys.orderCriterion.rawValue)
        }
        
        // 오름차순/내림차순 여부 초기화
        if UserDefaults.standard.string(forKey: UserDefaultsKeys.isOrderAscending.rawValue) == nil {
            UserDefaults.standard.setValue(false, forKey: UserDefaultsKeys.isOrderAscending.rawValue)
        }
        
        // 다크모드 적용 여부 초기화
        if UserDefaults.standard.string(forKey: UserDefaultsKeys.darkModeTheme.rawValue) == nil {
            UserDefaults.standard.setValue(
                DarkModeTheme.systemTheme.rawValue,
                forKey: UserDefaultsKeys.darkModeTheme.rawValue
            )
        }
        
        // 테마 색 초기화
        if UserDefaults.standard.string(forKey: UserDefaultsKeys.themeColor.rawValue) == nil {
            UserDefaults.standard.set(ThemeColor.black.rawValue, forKey: UserDefaultsKeys.themeColor.rawValue)
        }
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print(#function)
        
        if let memoMakingVC {
            memoMakingVC.completeMaking()
            print("새로 만들던 메모 저장함")
        }
        
        if let memoEditingVC {
            memoEditingVC.completeEditing()
            print("편집하던 메모 변경 내용 저장")
        }
        
    }
    
    
    
    

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "NoteCardCoreData")
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

    // MARK: - Core Data Saving support

    func saveContext () {
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

