//
//  SettingsViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/16.
//

import UIKit
import Shared
import Combine

class SettingsViewController: UITableViewController {
    
    var settingTitles: [[String]] = [
        
        //design
        //표시 순서는 각 컬렉션뷰에서 선택
        [L10n.Settings.themeColor,
         L10n.Settings.timeFormat,
         L10n.Settings.displayOrder,
         L10n.Settings.darkMode
        ],
        //표시 순서 대신, 표시 안의 하위 항목으로 앱 잠금 시 표시 방법? 이런 걸 써도 좋을 듯. (앱 잠금 시 제목만 보일 건지, 아니면 수정 날짜만 보일 건지...등)
        //그리고 표시 안의 하위 항목으로 다른 것들 도 표시할 수 있으니...
        
        //data
        //"메모 검색" 기능은 추후 아예 탭으로 빼 버릴 수도 있음.
        [L10n.Settings.totalMemos, L10n.Settings.totalCategories, L10n.MemoView.trash, L10n.Settings.emptyTrash],
        
        //contact
        [L10n.Settings.version]
        
    ]
    
    let settingsTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: UITableView.Style.insetGrouped)
        tableView.register(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.cellID)
        tableView.contentInset.top = 0
        tableView.contentInset.top = 17
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupNaviBar()
        setupDelegates()
        setSubscriptions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    override func willMove(toParent parent: UIViewController?) {
        print(#function)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.tableView.reloadRows(at: [IndexPath(row: 3, section: 0)], with: UITableView.RowAnimation.none)
    }
    
    private func setupUI() {
        self.tableView = self.settingsTableView
    }
    
    private func setupNaviBar() {
        
        self.title = L10n.TabBar.settings
        
        let standardAppearance: UINavigationBarAppearance = {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            return appearance
        }()
        
        let scrollEdgeAppearance: UINavigationBarAppearance = {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            return appearance
        }()
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .automatic
        self.navigationController?.navigationBar.standardAppearance = standardAppearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
    }
    
    private func setupDelegates() {
        self.settingsTableView.dataSource = self
        self.settingsTableView.delegate = self
    }
    
    private func setSubscriptions() {
        
        ThemeManager.shared.currentThemePublisher
            .subscribe(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
}


extension SettingsViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.settingTitles.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return self.settingTitles[section].count }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.cellID, for: indexPath) as? SettingsTableViewCell else { fatalError() }
        
        switch indexPath {
        case IndexPath(row: 0, section: 0):
            guard let currentTheme = UserDefaults.standard.string(forKey: UserDefaultsKeys.themeColor.rawValue) else { fatalError() }
            var secondaryText: String = ""
            
            switch currentTheme {

            case ThemeColor.black.rawValue:
                secondaryText = L10n.ThemeColor.blackWhite
            case ThemeColor.brown.rawValue:
                secondaryText = L10n.ThemeColor.brown
            case ThemeColor.red.rawValue:
                secondaryText = L10n.ThemeColor.red
            case ThemeColor.orange.rawValue:
                secondaryText = L10n.ThemeColor.orange
            case ThemeColor.yellow.rawValue:
                secondaryText = L10n.ThemeColor.yellow
            case ThemeColor.green.rawValue:
                secondaryText = L10n.ThemeColor.green
            case ThemeColor.skyBlue.rawValue:
                secondaryText = L10n.ThemeColor.skyblue
            case ThemeColor.blue.rawValue:
                secondaryText = L10n.ThemeColor.blue
            case ThemeColor.purple.rawValue:
                secondaryText = L10n.ThemeColor.purple
            default:
                secondaryText = L10n.ThemeColor.black
                
            }
            
            cell.configureCell(image: UIImage(systemName: "paintpalette")?.withRenderingMode(UIImage.RenderingMode.alwaysOriginal),
                               text: self.settingTitles[indexPath.section][indexPath.row],
                               secondaryText: secondaryText,
                               accesoryType: UITableViewCell.AccessoryType.disclosureIndicator
            )
            
        case IndexPath(row: 1, section: 0):
            let isTimeFormat24 = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isTimeFormat24.rawValue)
            cell.configureCell(image: UIImage(systemName: "clock"), 
                               text: self.settingTitles[indexPath.section][indexPath.row],
                               secondaryText: isTimeFormat24 ? L10n.Settings.format24h : L10n.Settings.format12h,
                               accesoryType: UITableViewCell.AccessoryType.disclosureIndicator
            )
            
        case IndexPath(row: 2, section: 0):
            guard let userDefaultCriterion = UserDefaults.standard.string(forKey: UserDefaultsKeys.orderCriterion.rawValue) else { fatalError() }
            let userDefautlAscendingValue = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isOrderAscending.rawValue)
            let currentState1: String
            let currentState2: String
            
            switch userDefaultCriterion {
            case OrderCriterion.modificationDate.rawValue:
                currentState1 = L10n.Settings.modificationLabel
            case OrderCriterion.creationDate.rawValue:
                currentState1 = L10n.Settings.creationLabel
            default:
                fatalError()
            }
            
            switch userDefautlAscendingValue {
            case true:
                currentState2 = L10n.Settings.ascendingLabel
            case false:
                currentState2 = L10n.Settings.descendingLabel
            }
            
            cell.configureCell(image: UIImage(systemName: "arrow.up.arrow.down.square"),
                               text: self.settingTitles[indexPath.section][indexPath.row],
                               secondaryText: "\(currentState1) / \(currentState2)",
                               accesoryType: UITableViewCell.AccessoryType.disclosureIndicator
            )
            
        case IndexPath(row: 3, section: 0):
            guard let darkModeTheme =
                    UserDefaults.standard.string(forKey: UserDefaultsKeys.darkModeTheme.rawValue) else { fatalError()}
            switch darkModeTheme {
            case DarkModeTheme.light.rawValue:
                cell.configureCell(image: UIImage(named: "darkModeSymbol"),
                                   text: self.settingTitles[indexPath.section][indexPath.row],
                                   secondaryText: L10n.Settings.lightMode,
                                   accesoryType: UITableViewCell.AccessoryType.disclosureIndicator
                )
                
            case DarkModeTheme.dark.rawValue:
                cell.configureCell(image: UIImage(named: "darkModeSymbol"),
                                   text: self.settingTitles[indexPath.section][indexPath.row],
                                   secondaryText: L10n.Settings.darkMode,
                                   accesoryType: UITableViewCell.AccessoryType.disclosureIndicator
                )
                
            case DarkModeTheme.systemTheme.rawValue:
                let configuration = UIImage.SymbolConfiguration(weight: UIImage.SymbolWeight.regular)
                
                cell.configureCell(image: UIImage(named: "darkModeSymbol", in: nil, with: configuration),
                                   text: self.settingTitles[indexPath.section][indexPath.row],
                                   secondaryText: L10n.Settings.systemMode,
                                   accesoryType: UITableViewCell.AccessoryType.disclosureIndicator
                )
                
            default:
                fatalError()
            }
            
            
        case IndexPath(row: 0, section: 1):
            let totalNumberOfMemo = MemoEntityManager.shared.getMemoEntitiesFromCoreData().count
            
            cell.configureCell(image: UIImage(systemName: "rectangle.portrait.on.rectangle.portrait"),
                               text: self.settingTitles[indexPath.section][indexPath.row],
                               secondaryText: "\(totalNumberOfMemo)",
                               accesoryType: UITableViewCell.AccessoryType.none
            )
            cell.selectionStyle = .none
            
        case IndexPath(row: 1, section: 1):
            let totalNumberOfCategory = CategoryEntityManager.shared.getCategoryEntities(inOrderOf: .modificationDate, isAscending: false).count
            cell.configureCell(image: UIImage(systemName: "circlebadge.2"),
                               text: self.settingTitles[indexPath.section][indexPath.row],
                               secondaryText: "\(totalNumberOfCategory)",
                               accesoryType: UITableViewCell.AccessoryType.none
            )
            cell.selectionStyle = .none
            
        case IndexPath(row: 2, section: 1):
            let numberOfMemoesInTrash = MemoEntityManager.shared.getMemoEntitiesInTrash().count
            cell.configureCell(image: UIImage(systemName: "trash")?.withTintColor(.systemGray).withRenderingMode(UIImage.RenderingMode.alwaysOriginal),
                               text: self.settingTitles[indexPath.section][indexPath.row],
                               secondaryText: "\(numberOfMemoesInTrash)",
                               accesoryType: UITableViewCell.AccessoryType.disclosureIndicator
            )
            
        case IndexPath(row: 3, section: 1):
            let numberOfMemoesInTrash = MemoEntityManager.shared.getMemoEntitiesInTrash().count
            
            cell.configureCell(text: self.settingTitles[indexPath.section][indexPath.row],
                               textColor: numberOfMemoesInTrash == 0 ? .lightGray : .currentTheme,
                               accesoryType: UITableViewCell.AccessoryType.none
            )
            
        case IndexPath(row: 0, section: 2):
            
            guard let currentAppName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String else { fatalError() }
            guard let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { fatalError() }
            guard let currentBuildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else { fatalError() }
            guard let currentBundleIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String else { fatalError() }
            
            cell.configureCell(text: self.settingTitles[indexPath.section][indexPath.row],
                               secondaryText: currentAppVersion,
                               accesoryType: UITableViewCell.AccessoryType.none
            )
            cell.selectionStyle = .none
            
            print("currentAppName: ", currentAppName)
            print("currentAppVersion: ", currentAppVersion)
            print("currentBuildVersion: ", currentBuildVersion)
            print("currentBundleIdentifier: ", currentBundleIdentifier)
            
        default:
            fatalError()
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            return L10n.Settings.trashRetentionMessage
        } else {
            return nil
        }
    }
    
}


extension SettingsViewController {
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard indexPath.section == 1, indexPath.row == 3 else { return indexPath }
        guard let cell = self.settingsTableView.cellForRow(at: indexPath) as? SettingsTableViewCell else { fatalError() }
        let numberOfMemoesInTrash = MemoEntityManager.shared.getMemoEntitiesInTrash().count
        if numberOfMemoesInTrash == 0 {
            return nil
        } else {
            return indexPath
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var targetVC: UIViewController?
        
        switch indexPath {
        case IndexPath(row: 0, section: 0):
            targetVC = ThemeColorPickingViewController()
        case IndexPath(row: 1, section: 0):
            targetVC = TimeFormatSettingViewController()
        case IndexPath(row: 2, section: 0):
            targetVC = OrderSettingViewController()
        case IndexPath(row: 3, section: 0):
            targetVC = DarkModeSettingViewController()
            
        case IndexPath(row: 2, section: 1):
            targetVC = MemoViewController(memoVCType: .trash)
        case IndexPath(row: 3, section: 1):
            showDeleteAllAlert(indexPath: indexPath)
            
        default:
            return
        }
        
        if let targetVC {
            showDetailView(viewController: targetVC)
        }
    }
    
    private func showDetailView(viewController: UIViewController) {
        
        let naviCon = UINavigationController(rootViewController: viewController)
        if let splitViewController {
            splitViewController.showDetailViewController(naviCon, sender: self)
        } else {
            self.navigationController?.pushViewController(viewController, animated: true)
        }
//        
//        guard let splitVC = self.splitViewController else {
//            self.navigationController?.pushViewController(viewController, animated: true)
//            return
//        }
//        
//        if splitVC.isCollapsed {
//            self.navigationController?.pushViewController(viewController, animated: true)
//        } else {
//            let naviCon = UINavigationController(rootViewController: viewController)
//            splitVC.setViewController(naviCon, for: .secondary)
//        }
    }
    
    private func showDeleteAllAlert(indexPath: IndexPath) {
        let alertCon = UIAlertController(
            title: L10n.Settings.emptyTrash,
            message: L10n.Settings.emptyTrashConfirm,
            preferredStyle: UIAlertController.Style.actionSheet)
        let deleteAction = UIAlertAction(
            title: L10n.Settings.emptyTrash,
            style: UIAlertAction.Style.destructive,
            handler: { [weak self] action in
                guard let self else { fatalError() }
                let memoEntitiesInTrash = MemoEntityManager.shared.getMemoEntitiesInTrash()
                memoEntitiesInTrash.forEach { memoEntity in
                    MemoEntityManager.shared.deleteMemoEntity(memoEntity: memoEntity)
                }
                self.settingsTableView.reloadRows(at: [indexPath, IndexPath(row: indexPath.row - 1, section: indexPath.section)], with: UITableView.RowAnimation.automatic)
                
            })
        
        let cancelAction = UIAlertAction(
            title: L10n.Common.cancel,
            style: UIAlertAction.Style.cancel,
            handler: { [weak self] action in
                guard let self else { fatalError() }
                self.settingsTableView.reloadRows(at: [indexPath, IndexPath(row: indexPath.row - 1, section: indexPath.section)], with: UITableView.RowAnimation.automatic)
            })
        alertCon.addAction(deleteAction)
        alertCon.addAction(cancelAction)
        
        // 아이패드에서 ActionSheet는 popoverPresentationController 설정이 필요함 (크래시 방지)
        if let popoverController = alertCon.popoverPresentationController {
            popoverController.sourceView = self.tableView
            popoverController.sourceRect = self.tableView.rectForRow(at: indexPath)
            popoverController.permittedArrowDirections = [.up, .down]
        }
        
        self.present(alertCon, animated: true)
    }
    
}
