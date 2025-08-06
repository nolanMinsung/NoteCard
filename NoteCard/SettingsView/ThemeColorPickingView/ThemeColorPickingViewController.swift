//
//  ThemeColorPickingViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/12/20.
//

import UIKit

final class ThemeColorPickingViewController: UIViewController {
    
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
    
//    let barTintColorChangeAnimation = UIViewPropertyAnimator(duration: 1, dampingRatio: 1)
    
    lazy var themeColorPickingView = self.view as! ThemeColorPickingView
    lazy var themeColorPickingTableView = self.themeColorPickingView.themeColorPickingTableView
    
    override func loadView() {
        self.view = ThemeColorPickingView()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNaviBar()
        setupDelegates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.selectCurrentColor()
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
        
        self.themeColorPickingTableView.dataSource = self
        self.themeColorPickingTableView.delegate = self
    }
    
    private func selectCurrentColor() {
        guard let themeColorHex = UserDefaults.standard.string(forKey: UserDefaultsKeys.themeColor.rawValue) else { fatalError() }
        guard let indexRowToSelect = ThemeColor.allCases.firstIndex(where: { $0.rawValue == themeColorHex }) else { fatalError() }
        self.themeColorPickingTableView.selectRow(at: IndexPath(row: indexRowToSelect, section: 0), animated: false, scrollPosition: .none)
    }
    
}



extension ThemeColorPickingViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ThemeColor.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ThemeColorPickingTableViewCell.cellID, for: indexPath) as? ThemeColorPickingTableViewCell else { fatalError("cell dequeuing failed!") }
        
        cell.configureCell(themeColor: self.themeColorsArray[indexPath.row], accesoryType: UITableViewCell.AccessoryType.none)
        
        return cell
    }
    
}


extension ThemeColorPickingViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ThemeColorPickingTableViewCell else { fatalError() }
        cell.isSelected = true
        
        ThemeManager.shared.setThemeColor(ThemeColor.allCases[indexPath.row])
        UIWindow.current?.tintColor = .currentTheme
        self.navigationController?.navigationBar.tintColor = .currentTheme
    }
    
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ThemeColorPickingTableViewCell else { fatalError() }
        cell.isSelected = false
    }
    
}
