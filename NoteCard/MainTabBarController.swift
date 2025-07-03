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
        
        setTabBarAppearance()
        initialViewControllersSetting()
        setTabBarItemSetting()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureHierarchy()
        setupConstraints()
    }
    
    private func setTabBarAppearance() {
        let standardAppearance = UITabBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        tabBar.standardAppearance = standardAppearance
        
        tabBar.tintColor = UIColor.currentTheme()
    }
    
    private func initialViewControllersSetting() {
        // tab 0: 홈 화면
        let homeNaviCon = UINavigationController(rootViewController: HomeViewController())
        
        // tab 1: 카테고리 없음.
        let uncategorizedMemoVC = MemoViewController(memoVCType: .uncategorized)
        let noCategoriesCardNaviCon = UINavigationController(rootViewController: uncategorizedMemoVC)
        noCategoriesCardNaviCon.navigationController?.toolbar.tintColor = .currentTheme()
        
        // tab: 2: 빠른 메모
        let quickMemoEmptyNaviCon = UINavigationController(rootViewController: QuickMemoEmptyViewController())
        
        // tab 3: 메모 검색
        let totalListNaviCon = UINavigationController(rootViewController: TotalListViewController())
        
        // tab 4: 설정
        let settingNaviCon = UINavigationController(rootViewController: SettingsViewController())
        
        self.setViewControllers(
            [homeNaviCon, noCategoriesCardNaviCon, quickMemoEmptyNaviCon, totalListNaviCon, settingNaviCon],
            animated: true
        )
    }
    
    private func setTabBarItemSetting() {
        self.tabBar.items?[0].title = "홈 화면".localized()
        self.tabBar.items?[0].image = UIImage(systemName: "house")
        self.tabBar.items?[1].title = "카테고리 없음".localized()
        self.tabBar.items?[1].image = UIImage(systemName: "app.dashed")
        self.tabBar.items?[2].title = "빠른 메모".localized()
        self.tabBar.items?[2].image = UIImage(systemName: "plus.app")
        self.tabBar.items?[3].title = "메모 검색".localized()
        self.tabBar.items?[3].image = UIImage(systemName: "magnifyingglass")
        self.tabBar.items?[4].title = "설정".localized()
        self.tabBar.items?[4].image = UIImage(systemName: "gearshape.2")
    }
    
    private func configureHierarchy() {
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
