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
        
        self.window = UIWindow(windowScene: windowScene)
        self.window?.makeKeyAndVisible()
        self.window?.tintColor = UIColor.currentTheme()
        
        let mainTabBarCon = MainTabBarController()
        self.window?.rootViewController = mainTabBarCon
        self.window?.backgroundColor = .clear
        
        // 다크모드 설정값 window에 반영하기.
        
        // 설정에서 다크모드 세팅 UserDefault 값에 해당하는 문자열
        guard let darkModeSettingRawValue = UserDefaults.standard.string(
            forKey: UserDefaultsKeys.darkModeTheme.rawValue
        ) else {
            fatalError("다크모드 설정값이 초기화되지 않았습니다.")
        }
        
        let darKModeValue = DarkModeTheme(rawValue: darkModeSettingRawValue)
        switch darKModeValue {
        case .light:
            window?.overrideUserInterfaceStyle = UIUserInterfaceStyle.light
        case .dark:
            window?.overrideUserInterfaceStyle = UIUserInterfaceStyle.dark
        default:
            window?.overrideUserInterfaceStyle = UIUserInterfaceStyle.unspecified
        }
        
        // 초기 화면은 홈 화면으로 설정.
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

