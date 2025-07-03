//
//  DarkModeSettingViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2024/1/29.
//

import UIKit

final class DarkModeSettingViewController: UIViewController {
    
    let themeColorsArray: [UIColor] = [
        .themeColorBlack,
        .themeColorBrown,
        .themeColorRed,
        .themeColorOrange,
        .themeColorYellow,
        .themeColorGreen,
        .themeColorSkyBlue,
        .themeColorBlue,
        .themeColorPurple
    ]
    
    
    
    let barTintColorChangeAnimation = UIViewPropertyAnimator(duration: 1, dampingRatio: 1)
    
    lazy var darkModeSettingView = self.view as! DarkModeSettingView
    lazy var darkModeSettingTableView = self.darkModeSettingView.darkModeSettingTableView
    
    override func loadView() {
        self.view = DarkModeSettingView()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNaviBar()
        setupDelegates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.selectCurrentMode()
    }
    
    private func setupNaviBar() {
        self.title = "테마 색 선택".localized()
        
        let standardAppearance: UINavigationBarAppearance = {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            return appearance
        }()
        
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.navigationBar.standardAppearance = standardAppearance
    }
    
    private func setupDelegates() {
        
        self.darkModeSettingTableView.dataSource = self
        self.darkModeSettingTableView.delegate = self
    }
    
    private func selectCurrentMode() {
        guard let darkModeTheme = UserDefaults.standard.string(forKey: UserDefaultsKeys.darkModeTheme.rawValue) else { fatalError() }
        switch darkModeTheme {
        case DarkModeTheme.light.rawValue:
            print(self.traitCollection.userInterfaceStyle.rawValue)
            self.darkModeSettingTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        case DarkModeTheme.dark.rawValue:
            print(self.traitCollection.userInterfaceStyle.rawValue)
            self.darkModeSettingTableView.selectRow(at: IndexPath(row: 1, section: 0), animated: false, scrollPosition: .none)
        case DarkModeTheme.systemTheme.rawValue:
            print(self.traitCollection.userInterfaceStyle.rawValue)
            self.darkModeSettingTableView.selectRow(at: IndexPath(row: 2, section: 0), animated: false, scrollPosition: .none)
        default:
            fatalError()
        }
        
    }
    
}



extension DarkModeSettingViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
//        let userInterfaceStyle = self.traitCollection.userInterfaceStyle
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DarkModeSettingTableViewCell.cellID, for: indexPath) as? DarkModeSettingTableViewCell else { fatalError("cell dequeuing failed!") }
        
        switch indexPath.row {
        case 0:
            cell.configureCell(userInterfaceStyle: .light)
        case 1:
            cell.configureCell(userInterfaceStyle: .dark)
        case 2:
            cell.configureCell(userInterfaceStyle: .unspecified)
        default:
            fatalError()
        }
        
        return cell
    }
    
}


extension DarkModeSettingViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? DarkModeSettingTableViewCell else { fatalError() }
        let userInterfaceStyle = cell.userInterfaceStyle
        
        cell.isSelected = true
        
        guard let currentWindow = UIWindow.current else { fatalError() }
        UIView.transition(with: currentWindow, duration: 0.3, options: UIView.AnimationOptions.transitionCrossDissolve, animations: {
            currentWindow.overrideUserInterfaceStyle = userInterfaceStyle
        }, completion: nil)
        
        switch userInterfaceStyle {
        case .light:
            UserDefaults.standard.setValue(DarkModeTheme.light.rawValue, forKey: UserDefaultsKeys.darkModeTheme.rawValue)
        case .dark:
            UserDefaults.standard.setValue(DarkModeTheme.dark.rawValue, forKey: UserDefaultsKeys.darkModeTheme.rawValue)
        case .unspecified:
            UserDefaults.standard.setValue(DarkModeTheme.systemTheme.rawValue, forKey: UserDefaultsKeys.darkModeTheme.rawValue)
        @unknown default:
            fatalError()
        }
    }
    
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? DarkModeSettingTableViewCell else { fatalError() }
        cell.isSelected = false
    }
    
}
