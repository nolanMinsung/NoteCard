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
        
    }

}

