//
//  SceneDelegate.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        //MemoView(와 TotalListView)에서 기기의 화면 사이즈를 얻기 위해 window에 접근하는 코드가 존재. (UIWindow 및 UIScreen 의 extension 참고)
        //이때 접근하는 window가 keyWindow인지 확인하는 과정이 존재.
        //그래서 앱 상의 어떤 MemoView(와 TotalListView)를 부르더라도 해당 뷰의 window를 keyWindow로 만드는 과정이 선행되어야 함.
        //아래 코드들을 쭉 보면 현재 메서드(willConnectTo) 안에서 세번째 탭에 해당하는 뷰컨트롤러를 생성하는데, 이 뷰컨트롤러가 MemoViewController라서 MemoView를 생성하게 됨.
        //따라서 window.makeKeyAndVisible() 코드를 맨 앞으로 뺀 것
        //window의 rootViewController 에 값을 할당하는 것은 tabBarCon의 viewController를 모두 생성하고 난 뒤에 실행해야 하므로,
        //window의 rootViewController에 값을 할당하는 코드(를 포함한 다른 window관련 코드)들은 이 메서드의 마지막 부분으로 뺐음.
        
        self.window = UIWindow(windowScene: windowScene)
        self.window?.makeKeyAndVisible()
        self.window?.tintColor = UIColor.currentTheme()
        
        let mainTabBarCon = MainTabBarController()
        self.window?.rootViewController = mainTabBarCon
        mainTabBarCon.delegate = self.window
        self.window?.windowScene?.keyWindow?.backgroundColor = .clear //그냥 window?backgroundColor = .clear랑 뭐가 다르지?
        
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.dateFormat.rawValue)
        
        
        // 설정값들 초기화
        
        // 테마 색상 초기화
        if UserDefaults.standard.string(forKey: UserDefaultsKeys.themeColor.rawValue) == nil {
            UserDefaults.standard.set(ThemeColor.blue.rawValue, forKey: UserDefaultsKeys.themeColor.rawValue)
            self.window?.tintColor = UIColor.themeColorBlue
            mainTabBarCon.tabBar.tintColor = UIColor.themeColorBlue
        }
        
//        if UserDefaults.standard.string(forKey: KeysForUserDefaults.dateFormat.rawValue) == nil {
//            UserDefaults.standard.setValue("yyyy. M. d. (EEE)", forKey: KeysForUserDefaults.dateFormat.rawValue)
//        }
        
        // 시간 표시형식 초기화
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
            UserDefaults.standard.setValue(DarkModeTheme.systemTheme.rawValue, forKey: UserDefaultsKeys.darkModeTheme.rawValue)
        } else {
            guard let darkModeUserDefault =
                    UserDefaults.standard.string(forKey: UserDefaultsKeys.darkModeTheme.rawValue) else { fatalError() }
            switch darkModeUserDefault {
            case DarkModeTheme.light.rawValue:
                guard let window else { fatalError() }
                window.overrideUserInterfaceStyle = UIUserInterfaceStyle.light
            case DarkModeTheme.dark.rawValue:
                guard let window else { fatalError() }
                window.overrideUserInterfaceStyle = UIUserInterfaceStyle.dark
                
            default:
                guard let window else { fatalError() }
                window.overrideUserInterfaceStyle = UIUserInterfaceStyle.unspecified
            }
        }
        
        mainTabBarCon.selectedIndex = 0
//        while true {
//            print("^____^")
////            if uncategorizedMemoVC.largeCardCollectionView.window != nil && uncategorizedMemoVC.smallCardCollectionView.window != nil {
//            if uncategorizedMemoVC.viewIfLoaded != nil {
//                mainTabBarCon.selectedIndex = 0
//                break
//            } else {
//                continue
//            }
//        }
        
        
//        let memoEntitiesInTrash = MemoEntityManager.shared.getMemoEntitiesInTrash(inOrderOf: .modificationDate, isAscending: false)
//        memoEntitiesInTrash.forEach { memo in
//            
//            guard let deletedDate = memo.deletedDate else { fatalError() }
//            let calendar = Calendar.init(identifier: Calendar.Identifier.gregorian)
//            
//            guard let dayAfterDeleted = calendar.dateComponents([.day], from: deletedDate, to: Date()).day else { fatalError() }
//            guard let hourAfterDeleted = calendar.dateComponents([.hour], from: deletedDate, to: Date()).hour else { fatalError() }
//            
//            if dayAfterDeleted >= 14 {
//                print(dayAfterDeleted)
//                print("~~~")
//                MemoEntityManager.shared.deleteMemoEntity(memoEntity: memo)
//            }
//        }
        
        
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        print(#function)
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
        
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let keyWindows = windowScene.windows.filter { $0.isKeyWindow }
        let keyWindow = keyWindows.first
        print(keyWindow?.rootViewController is UITabBarController)
        
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        print(#function)
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
        guard let mainTabBarCon = self.window?.rootViewController as? MainTabBarController else { fatalError() }
        
        let blurAnimator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1)
        blurAnimator.addAnimations {
            mainTabBarCon.blurView.effect = nil
        }
        
        blurAnimator.addCompletion { animatingPosition in
            mainTabBarCon.blurView.isUserInteractionEnabled = false
            mainTabBarCon.isUncategorizedMemoVCHasShown = true
        }
        
        if !mainTabBarCon.isUncategorizedMemoVCHasShown {
            mainTabBarCon.selectedIndex = 0
            blurAnimator.startAnimation()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        print(#function)
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        print(#function)
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        
        let memoEntitiesInTrash = MemoEntityManager.shared.getMemoEntitiesInTrash()
        memoEntitiesInTrash.forEach { memo in
            
            guard let deletedDate = memo.deletedDate else { fatalError() }
            let calendar = Calendar.init(identifier: Calendar.Identifier.gregorian)
            
            guard let dayAfterDeleted = calendar.dateComponents([.day], from: deletedDate, to: Date()).day else { fatalError() }
            guard let hourAfterDeleted = calendar.dateComponents([.hour], from: deletedDate, to: Date()).hour else { fatalError() }
            
            if dayAfterDeleted >= 14 {
                print(dayAfterDeleted)
                print("~~~")
                MemoEntityManager.shared.deleteMemoEntity(memoEntity: memo)
            }
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        print(#function)
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
    
    
    private func moveToHomeVC() {
        guard let mainTaBarCon = self.window?.rootViewController as? UITabBarController else { fatalError() }
        
        if mainTaBarCon.viewControllers?[1].view.window != nil {
            
        }
        
        
    }
    
    
}

