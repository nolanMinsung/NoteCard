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
    
    var blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        return blurView
    }()
    
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
        configureViewHierarchy()
        setupConstraints()
    }
    
    private func setTabBarDesign() {
        let standardAppearance = UITabBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        tabBar.standardAppearance = standardAppearance
        
        tabBar.tintColor = UIColor.currentTheme()
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
        noCategoriesCardNaviCon.navigationController?.toolbar.tintColor = .currentTheme()
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
        let totalListNaviCon = UINavigationController(rootViewController: TotalListViewController())
        totalListNaviCon.tabBarItem = UITabBarItem(
            title: "메모 검색".localized(),
            image: UIImage(systemName: "magnifyingglass"),
            selectedImage: UIImage(systemName: "magnifyingglass")
        )
        
        // tab 4: 설정
        let settingNaviCon = UINavigationController(rootViewController: SettingsViewController())
        settingNaviCon.tabBarItem = UITabBarItem(
            title: "설정".localized(),
            image: UIImage(systemName: "gearshape.2"),
            selectedImage: UIImage(systemName: "gearshape.2.fill")
        )
        
        // tab 5: 설정
        self.setViewControllers(
            [homeNaviCon, noCategoriesCardNaviCon, thirdTabViewController, totalListNaviCon, settingNaviCon],
            animated: true
        )
    }
    
    private func configureViewHierarchy() {
        self.view.addSubview(self.blurView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate(
            [self.blurView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0),
             self.blurView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0),
             self.blurView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0),
             self.blurView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0)]
        )
    }
    
}


extension MainTabBarController: UITabBarControllerDelegate {
    
    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        // 빠른 메모를 탭했을 때만 대응
        if viewController is ThirdTabViewController {
            // 빠른 메모를 탭했을 때 '카테고리 없음'에서 메모 수정중이면, 수정 멈추기(키보드 내리기)
            if selectedIndex == 1 {
                viewControllers?[1].view.endEditing(true)
            }
            
            let memoMakingVC = MemoMakingViewController()
            let memoMakingNaviCon = UINavigationController(rootViewController: memoMakingVC)
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
            appDelegate.memoMakingVC = memoMakingVC
            memoMakingNaviCon.modalPresentationStyle = .formSheet
            tabBarController.present(memoMakingNaviCon, animated: true)
            
            return false
        } else {
            return true
        }
        
    }
    
}
