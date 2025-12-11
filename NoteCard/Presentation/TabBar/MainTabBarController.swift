//
//  MainTabBarController.swift
//  NoteCard
//
//  Created by 김민성 on 2024/01/30.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    var previousSelectedIndex: Int = 0
    
    var isUncategorizedMemoVCHasShown: Bool = false
    
    // MARK: - Initialize
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        setTabBarDesign()
        initialViewControllersSetting()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
//        configureViewHierarchy()
//        setupConstraints()
    }
    
    private func setTabBarDesign() {
        let standardAppearance = UITabBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        tabBar.standardAppearance = standardAppearance
        
        tabBar.tintColor = UIColor.currentTheme
    }
    
    /// Note:
    /// 탭바 아이템의 경우, 탭바 컨트롤러에서 직접 설정하는 것이 아니라, 각 뷰컨트롤러의 tabBarItem을 설정해 주어야 함.
    /// https://developer.apple.com/documentation/uikit/uitabbarcontroller#overview
    private func initialViewControllersSetting() {
        // tab 0: 홈 화면
        let homeNaviCon = UINavigationController(rootViewController: HomeViewController())
        homeNaviCon.tabBarItem = UITabBarItem(
            title: "홈 화면",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        
        // tab 1: 카테고리 없음.
        let uncategorizedMemoVC = MemoViewController(memoVCType: .uncategorized)
        let noCategoriesCardNaviCon = UINavigationController(rootViewController: uncategorizedMemoVC)
        noCategoriesCardNaviCon.navigationController?.toolbar.tintColor = .currentTheme
        noCategoriesCardNaviCon.tabBarItem = UITabBarItem(
            title: "카테고리 없음".localized(),
            image: UIImage(systemName: "app.dashed"),
            selectedImage: UIImage(systemName: "inset.filled.square.dashed")
        )
        
        // tab: 2: 빠른 메모 , 탭바 컨트롤러에 실제로는 메모 작성 VC 대신 ThirdTabViewController가 들어감.
        let thirdTabViewController = ThirdTabViewController()
        thirdTabViewController.tabBarItem = UITabBarItem(
            title: "빠른 메모".localized(),
            image: UIImage(systemName: "plus.app"),
            selectedImage: UIImage(systemName: "plus.app")
        )
        
        // tab 3: 메모 검색
        let memoSearchingVC = MemoSearchingViewController()
        let memoSearchingNaviCon = UINavigationController(rootViewController: memoSearchingVC)
        memoSearchingNaviCon.tabBarItem = UITabBarItem(
            title: "메모 검색".localized(),
            image: UIImage(systemName: "magnifyingglass"),
            selectedImage: UIImage(systemName: "magnifyingglass")
        )
        
        // tab 4: 설정(UISplitViewController)
        let settingsVC = SettingsViewController()
        let settingsNaviCon = UINavigationController(rootViewController: settingsVC)
        
        let emptyDetailVC = SettingsPlaceholderViewController()
        let emptyDetailNaviCon = UINavigationController(rootViewController: emptyDetailVC)
        
        let splitVC: UISplitViewController
        
        if #available(iOS 18.0, *) {
            splitVC = UISplitViewController(style: .doubleColumn)
            splitVC.setViewController(settingsVC, for: .primary)
            splitVC.setViewController(emptyDetailNaviCon, for: .secondary)
            splitVC.preferredSplitBehavior = .tile
        } else {
            splitVC = UISplitViewController()
            splitVC.viewControllers = [settingsNaviCon, emptyDetailNaviCon]
        }
        
        splitVC.delegate = self
        splitVC.preferredDisplayMode = .oneBesideSecondary
        splitVC.tabBarItem = UITabBarItem(
            title: "설정".localized(),
            image: UIImage(systemName: "gearshape.2"),
            selectedImage: UIImage(systemName: "gearshape.2.fill")
        )
        
        self.setViewControllers(
            [
                homeNaviCon,
                noCategoriesCardNaviCon,
                thirdTabViewController,
                memoSearchingNaviCon,
                splitVC
            ],
            animated: true
        )
    }
    
}


extension MainTabBarController: UITabBarControllerDelegate {
    
    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // 빠른 메모를 탭했을 때만 대응
        guard viewController is ThirdTabViewController else {
            return true
        }
        let memoMakingVC = MemoDetailViewController(type: .making(category: nil))
        let memoMakingNaviCon = UINavigationController(rootViewController: memoMakingVC)
        
        memoMakingNaviCon.modalPresentationStyle = .formSheet
        tabBarController.present(memoMakingNaviCon, animated: true)
        return false
    }
    
}

// MARK: - UISplitViewControllerDelegate
extension MainTabBarController: UISplitViewControllerDelegate {
    
    func splitViewController(
        _ svc: UISplitViewController,
        topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column
    ) -> UISplitViewController.Column {
        guard let secondaryNaviCon = svc.viewController(for: .secondary) as? UINavigationController,
              let topVC = secondaryNaviCon.topViewController
        else {
            return .primary
        }
        
        if topVC is SettingsPlaceholderViewController {
            return .primary
        } else {
            return .secondary
        }
    }
    
    func splitViewController(
        _ splitViewController: UISplitViewController,
        collapseSecondary secondaryViewController: UIViewController,
        onto primaryViewController: UIViewController
    ) -> Bool {
        guard let secondaryNaviCon = secondaryViewController as? UINavigationController,
              let topVC = secondaryNaviCon.topViewController else {
            return true
        }
        
        // 빈 화면(Placeholder)인 경우 목록만 보여줌
        return topVC is SettingsPlaceholderViewController
    }
    
}
