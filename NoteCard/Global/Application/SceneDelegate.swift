//
//  SceneDelegate.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import Combine
import UIKit
import Data
import Domain
import DesignSystem
import LoginFeature
import Shared
import SyncInterface

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var cancellables = Set<AnyCancellable>()
    private var signInProgressOverlay: SignInProgressOverlay?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }

        self.window = UIWindow(windowScene: windowScene)
        self.window?.makeKeyAndVisible()
        self.window?.tintColor = UIColor.currentTheme
        self.window?.backgroundColor = .clear

        // 다크모드 설정값 window에 반영하기.
        applyDarkModeSetting()

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("AppDelegate를 찾을 수 없습니다.")
        }

        // 신규 사용자(익명 데이터 없음 + 아직 안내를 본 적 없음)에게만 로그인 화면을 띄움.
        // 그 외(기존 사용자 / 이미 안내 본 사람)는 홈 화면으로 직행.
        if shouldShowLoginScreen(environment: appDelegate.environment) {
            self.window?.rootViewController = makeLoginViewController(environment: appDelegate.environment)
        } else {
            self.window?.rootViewController = makeMainTabBarController(environment: appDelegate.environment)
        }

        observeAuthStateChanges(environment: appDelegate.environment)
        observeReadinessPhase(environment: appDelegate.environment)
    }

    /// readiness gate phase 에 따라 window 위에 SignInProgressOverlay 를 show / hide.
    /// rootVC 교체와 무관하게 살아남아 sign-in 흐름 전체 동안 터치 차단 + 단계 표시.
    private func observeReadinessPhase(environment: AppEnvironment) {
        environment.firstSignInReadinessCoordinator.phasePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] phase in
                self?.handle(phase: phase)
            }
            .store(in: &cancellables)
    }

    private func handle(phase: SignInPhase) {
        switch phase {
        case .idle, .ready:
            hideSignInProgressOverlay()
        case .signingIn, .uploading, .downloading:
            showSignInProgressOverlay(phase: phase)
        }
    }

    private func showSignInProgressOverlay(phase: SignInPhase) {
        guard let window = self.window else { return }
        let overlay = signInProgressOverlay ?? SignInProgressOverlay()
        if overlay.superview == nil {
            overlay.alpha = 0
            window.addSubview(overlay)
            NSLayoutConstraint.activate([
                overlay.topAnchor.constraint(equalTo: window.topAnchor),
                overlay.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: window.trailingAnchor),
                overlay.bottomAnchor.constraint(equalTo: window.bottomAnchor)
            ])
            signInProgressOverlay = overlay
            UIView.animate(withDuration: 0.2) { overlay.alpha = 1 }
        }
        overlay.update(phase: phase)
    }

    private func hideSignInProgressOverlay() {
        guard let overlay = signInProgressOverlay, overlay.superview != nil else { return }
        UIView.animate(withDuration: 0.2, animations: {
            overlay.alpha = 0
        }, completion: { [weak self] _ in
            overlay.removeFromSuperview()
            self?.signInProgressOverlay = nil
        })
    }

    /// auth 상태 전이 시 rootViewController 를 새 MainTabBar 로 교체해 modal · navigation 상태 reset.
    /// 사인인은 LoginVC 가 자체 transition 하므로 rootVC 가 LoginVC 가 아닌 경로만 처리.
    /// 사인아웃은 force signOut (sentinel / token 만료 등) 까지 커버.
    /// AccountDetail 에서의 sign-in 처럼 LoginVC 가 아닌 경로는 readiness gate 완료까지 transition 을 지연.
    /// 그래야 overlay 가 phase 라벨을 갱신하는 동안 UIView.transition 의 window snapshot 이 시각을 덮어쓰지 않음.
    private func observeAuthStateChanges(environment: AppEnvironment) {
        environment.authService.authStatePublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self else { return }
                if user == nil {
                    self.transitionToMainTabBar(environment: environment)
                } else if !(self.window?.rootViewController is LoginViewController) {
                    self.transitionAfterReadiness(environment: environment)
                }
            }
            .store(in: &cancellables)
    }

    /// phase 가 .ready 또는 .idle 이 될 때까지 기다린 뒤 transition. 현재 phase 가 이미 .ready / .idle 이면 즉시.
    /// readiness gate 가 동작 중인 동안은 overlay 가 살아남아 단계별 라벨 갱신을 사용자에게 보여줄 수 있음.
    private func transitionAfterReadiness(environment: AppEnvironment) {
        var cancellable: AnyCancellable?
        cancellable = environment.firstSignInReadinessCoordinator.phasePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] phase in
                guard phase == .ready || phase == .idle else { return }
                cancellable?.cancel()
                self?.transitionToMainTabBar(environment: environment)
            }
    }

    // MARK: - Root view construction

    private func makeMainTabBarController(environment: AppEnvironment) -> MainTabBarController {
        let mainTabBarCon = MainTabBarController(environment: environment)
        if #available(iOS 18.0, *) {
            mainTabBarCon.mode = .tabSidebar
        }
        mainTabBarCon.selectedIndex = 0
        return mainTabBarCon
    }

    private func makeLoginViewController(environment: AppEnvironment) -> LoginViewController {
        LoginViewController(
            authService: environment.authService,
            readinessCoordinator: environment.firstSignInReadinessCoordinator
        ) { [weak self] outcome in
            UserDefaults.standard.set(true, forKey: UserDefaultsKey.didShowSyncIntroduction.rawValue)
            switch outcome {
            case .signedIn, .skipped:
                self?.transitionToMainTabBar(environment: environment)
            }
        }
    }

    private func transitionToMainTabBar(environment: AppEnvironment) {
        guard let window = self.window else { return }
        let target = makeMainTabBarController(environment: environment)
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = target
        }
    }

    private func shouldShowLoginScreen(environment: AppEnvironment) -> Bool {
        // 안내(로그인 화면 또는 What's new 모달)를 한 번 본 사람은 다시 띄우지 않음.
        if UserDefaults.standard.bool(forKey: UserDefaultsKey.didShowSyncIntroduction.rawValue) {
            return false
        }
        // 익명 store에 메모/카테고리 흔적이 있다 = 기존 사용자 = 홈으로 진입 후 What's new 모달 대상.
        if AnonymousDataInspector.hasUserData(in: environment.coreDataStack) {
            return false
        }
        return true
    }

    private func applyDarkModeSetting() {
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
        
//        guard let mainTabBarCon = self.window?.rootViewController as? MainTabBarController else { fatalError() }
//        
//        let blurAnimator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1)
//        blurAnimator.addAnimations {
//            mainTabBarCon.blurView.effect = nil
//        }
//        
//        blurAnimator.addCompletion { animatingPosition in
//            mainTabBarCon.blurView.isUserInteractionEnabled = false
//            mainTabBarCon.isUncategorizedMemoVCHasShown = true
//        }
//        
//        if !mainTabBarCon.isUncategorizedMemoVCHasShown {
//            mainTabBarCon.selectedIndex = 0
//            blurAnimator.startAnimation()
//        }
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
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let memoRepository = appDelegate.environment.memoRepository
        Task {
            do {
                let trashMemos = try await memoRepository.getAllMemosInTrash()
                let calendar = Calendar(identifier: .gregorian)
                for memo in trashMemos {
                    guard let deletedDate = memo.deletedDate else { continue }
                    guard let dayAfterDeleted = calendar.dateComponents([.day], from: deletedDate, to: Date()).day else { continue }
                    if dayAfterDeleted >= 14 {
                        try await memoRepository.deleteMemo(memo)
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        print(#function)
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.environment.coreDataStack.saveContext()
    }
    
    
    private func moveToHomeVC() {
        guard let mainTaBarCon = self.window?.rootViewController as? UITabBarController else { fatalError() }
        
        if mainTaBarCon.viewControllers?[1].view.window != nil {
            
        }
        
        
    }
    
    
}

