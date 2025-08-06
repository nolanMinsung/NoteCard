//
//  SettingsViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/16.
//

import UIKit

class SettingsViewController: UITableViewController {
    
    var settingTitles: [[String]] = [
        
        //design
        //표시 순서는 각 컬렉션뷰에서 선택
        ["테마 색".localized(),
         "시간 표시 형식".localized(),
         "표시 순서".localized(),
         "다크 모드".localized()
        ],
        //표시 순서 대신, 표시 안의 하위 항목으로 앱 잠금 시 표시 방법? 이런 걸 써도 좋을 듯. (앱 잠금 시 제목만 보일 건지, 아니면 수정 날짜만 보일 건지...등)
        //그리고 표시 안의 하위 항목으로 다른 것들 도 표시할 수 있으니...
        
        //data
        //"메모 검색" 기능은 추후 아예 탭으로 빼 버릴 수도 있음.
        ["총 메모 수".localized(), "총 카테고리 수".localized(), "휴지통".localized(), "휴지통 비우기".localized()],
        
        //contact
        ["버전 정보".localized()]
        
    ]
    
    let settingsTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: UITableView.Style.insetGrouped)
        tableView.register(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.cellID)
        tableView.contentInset.top = 0
        tableView.contentInset.top = 17
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    
    
    
//    lazy var settingsView = self.view as! SettingsView
//    lazy var settingsTableView = self.settingsView.settingsTableView
    
    
//    override func loadView() {
//        self.view = SettingsView()
//    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupNaviBar()
        setupDelegates()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    
    override func willMove(toParent parent: UIViewController?) {
        print(#function)
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        self.settingsTableView.scrollToRow(at: IndexPath(row: 2, section: 2), at: UITableView.ScrollPosition.top, animated: true)
//    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.tableView.reloadRows(at: [IndexPath(row: 3, section: 0)], with: UITableView.RowAnimation.none)
    }
    
    
    private func setupUI() {
        self.tableView = self.settingsTableView
    }
    
    
    
    private func setupNaviBar() {
        
        self.title = "설정".localized()
        
        let standardAppearance: UINavigationBarAppearance = {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
//            appearance.backgroundColor = .systemGray6
            return appearance
        }()
        
        let scrollEdgeAppearance: UINavigationBarAppearance = {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
//            appearance.backgroundColor = .systemGray6
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
                secondaryText = "Black/White".localized()
            case ThemeColor.brown.rawValue:
                secondaryText = "Brown".localized()
            case ThemeColor.red.rawValue:
                secondaryText = "Red".localized()
            case ThemeColor.orange.rawValue:
                secondaryText = "Orange".localized()
            case ThemeColor.yellow.rawValue:
                secondaryText = "Yellow".localized()
            case ThemeColor.green.rawValue:
                secondaryText = "Green".localized()
            case ThemeColor.skyBlue.rawValue:
                secondaryText = "Skyblue".localized()
            case ThemeColor.blue.rawValue:
                secondaryText = "Blue".localized()
            case ThemeColor.purple.rawValue:
                secondaryText = "Purple".localized()
            default:
                secondaryText = "Black".localized()
                
            }
            
            
            
            cell.configureCell(image: UIImage(systemName: "paintpalette")?.withRenderingMode(UIImage.RenderingMode.alwaysOriginal),
                               text: self.settingTitles[indexPath.section][indexPath.row],
                               secondaryText: secondaryText,
                               accesoryType: UITableViewCell.AccessoryType.disclosureIndicator
            )
            
        case IndexPath(row: 1, section: 0):
            let isTimeFormat24 = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isTimeFormat24.rawValue)
//            cell.configureCell(
//                withName: self.settingTitles[indexPath.section][indexPath.row],
//                type: .pushing,
//                currentState: isTimeFormat24 ? "24시간제".localized() : "12시간제".localized())
            cell.configureCell(image: UIImage(systemName: "clock"), 
                               text: self.settingTitles[indexPath.section][indexPath.row],
                               secondaryText: isTimeFormat24 ? "24시간제".localized() : "12시간제".localized(),
                               accesoryType: UITableViewCell.AccessoryType.disclosureIndicator
            )
            
        case IndexPath(row: 2, section: 0):
            guard let userDefaultCriterion = UserDefaults.standard.string(forKey: UserDefaultsKeys.orderCriterion.rawValue) else { fatalError() }
            let userDefautlAscendingValue = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isOrderAscending.rawValue)
            let currentState1: String
            let currentState2: String
            
            switch userDefaultCriterion {
            case OrderCriterion.modificationDate.rawValue:
                currentState1 = "SettingsVC/수정 시간".localized()
            case OrderCriterion.creationDate.rawValue:
                currentState1 = "SettingsVC/만든 시간".localized()
            default:
                fatalError()
            }
            
            switch userDefautlAscendingValue {
            case true:
                currentState2 = "SettingsVC/오름차순".localized()
            case false:
                currentState2 = "SettingsVC/내림차순".localized()
            }
            
//            cell.configureCell(
//                withName: self.settingTitles[indexPath.section][indexPath.row],
//                type: .pushing,
//                currentState: "\(currentState1) / \(currentState2)")
            
            cell.configureCell(image: UIImage(systemName: "arrow.up.arrow.down.square"),
                               text: self.settingTitles[indexPath.section][indexPath.row],
                               secondaryText: "\(currentState1) / \(currentState2)",
                               accesoryType: UITableViewCell.AccessoryType.disclosureIndicator
            )
            
//        case IndexPath(row: 4, section: 0):
//            cell.configureCell(withName: self.settingTitles[indexPath.section][indexPath.row], type: .pushing)
            
            
        case IndexPath(row: 3, section: 0):
            guard let darkModeTheme =
                    UserDefaults.standard.string(forKey: UserDefaultsKeys.darkModeTheme.rawValue) else { fatalError()}
            switch darkModeTheme {
            case DarkModeTheme.light.rawValue:
//                cell.configureCell(
//                    withName: self.settingTitles[indexPath.section][indexPath.row],
//                    type: SettingsTableViewCell.SettingsTableViewCellType.pushing,
//                    currentState: "라이트 모드".localized()
//                )
                
                cell.configureCell(image: UIImage(named: "darkModeSymbol"),
                                   text: self.settingTitles[indexPath.section][indexPath.row],
                                   secondaryText: "라이트 모드".localized(),
                                   accesoryType: UITableViewCell.AccessoryType.disclosureIndicator
                )
                
                
            case DarkModeTheme.dark.rawValue:
//                cell.configureCell(
//                    withName: self.settingTitles[indexPath.section][indexPath.row],
//                    type: SettingsTableViewCell.SettingsTableViewCellType.pushing,
//                    currentState: "다크 모드".localized()
//                )
                
                cell.configureCell(image: UIImage(named: "darkModeSymbol"),
                                   text: self.settingTitles[indexPath.section][indexPath.row],
                                   secondaryText: "다크 모드".localized(),
                                   accesoryType: UITableViewCell.AccessoryType.disclosureIndicator
                )
                
            case DarkModeTheme.systemTheme.rawValue:
//                cell.configureCell(
//                    withName: self.settingTitles[indexPath.section][indexPath.row],
//                    type: SettingsTableViewCell.SettingsTableViewCellType.pushing,
//                    currentState: "시스템 모드".localized()
//                )
                let configuration = UIImage.SymbolConfiguration(weight: UIImage.SymbolWeight.regular)
                
                cell.configureCell(image: UIImage(named: "darkModeSymbol", in: nil, with: configuration),
                                   text: self.settingTitles[indexPath.section][indexPath.row],
                                   secondaryText: "시스템 모드".localized(),
                                   accesoryType: UITableViewCell.AccessoryType.disclosureIndicator
                )
                
            default:
                fatalError()
            }
            
            
        case IndexPath(row: 0, section: 1):
            let totalNumberOfMemo = MemoEntityManager.shared.getMemoEntitiesFromCoreData().count
//            cell.configureCell(
//                withName: self.settingTitles[indexPath.section][indexPath.row],
//                type: .none,
//                currentState: "\(totalNumberOfMemo)")
            
            cell.configureCell(image: UIImage(systemName: "rectangle.portrait.on.rectangle.portrait"),
                               text: self.settingTitles[indexPath.section][indexPath.row],
                               secondaryText: "\(totalNumberOfMemo)",
                               accesoryType: UITableViewCell.AccessoryType.none
            )
            cell.selectionStyle = .none
            
        case IndexPath(row: 1, section: 1):
            let totalNumberOfCategory = CategoryEntityManager.shared.getCategoryEntities(inOrderOf: .modificationDate, isAscending: false).count
//            cell.configureCell(
//                withName: self.settingTitles[indexPath.section][indexPath.row],
//                type: .none,
//                currentState: "\(totalNumberOfCategory)")
            
            cell.configureCell(image: UIImage(systemName: "circlebadge.2"),
                               text: self.settingTitles[indexPath.section][indexPath.row],
                               secondaryText: "\(totalNumberOfCategory)",
                               accesoryType: UITableViewCell.AccessoryType.none
            )
            cell.selectionStyle = .none
            
        case IndexPath(row: 2, section: 1):
            let numberOfMemoesInTrash = MemoEntityManager.shared.getMemoEntitiesInTrash().count
//            cell.configureCell(
//                withName: self.settingTitles[indexPath.section][indexPath.row],
//                type: .pushing,
//                currentState: "\(numberOfMemoesInTrash)")
            
            cell.configureCell(image: UIImage(systemName: "trash")?.withTintColor(.systemGray).withRenderingMode(UIImage.RenderingMode.alwaysOriginal),
                               text: self.settingTitles[indexPath.section][indexPath.row],
                               secondaryText: "\(numberOfMemoesInTrash)",
                               accesoryType: UITableViewCell.AccessoryType.disclosureIndicator
            )
            
        case IndexPath(row: 3, section: 1):
            let numberOfMemoesInTrash = MemoEntityManager.shared.getMemoEntitiesInTrash().count
//            cell.configureCell(
//                withName: self.settingTitles[indexPath.section][indexPath.row],
//                type: .button)
//            if numberOfMemoesInTrash == 0 {
//                cell.nameLabel.textColor = .lightGray
//            } else {
//                cell.nameLabel.textColor = .currentTheme
//            }
            
            cell.configureCell(text: self.settingTitles[indexPath.section][indexPath.row],
                               textColor: numberOfMemoesInTrash == 0 ? .lightGray : .currentTheme,
                               accesoryType: UITableViewCell.AccessoryType.none
            )
            
        case IndexPath(row: 0, section: 2):
            
            guard let currentAppName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String else { fatalError() }
            guard let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { fatalError() }
            guard let currentBuildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else { fatalError() }
            guard let currentBundleIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String else { fatalError() }
            
            
//            cell.configureCell(withName: self.settingTitles[indexPath.section][indexPath.row], type: .none, currentState: currentAppVersion)
            
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
            return "휴지통에 들어간 메모는 삭제된 지 2주가 지나면 영구적으로 삭제됩니다.".localized()
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
        print(self.settingTitles[indexPath.section][indexPath.row])
        
        switch indexPath {
        case IndexPath(row: 0, section: 0):
            self.navigationController?.pushViewController(ThemeColorPickingViewController(), animated: true)
        case IndexPath(row: 1, section: 0):
            self.navigationController?.pushViewController(TimeFormatSettingViewController(), animated: true)
        case IndexPath(row: 2, section: 0):
            self.navigationController?.pushViewController(OrderSettingViewController(), animated: true)
        case IndexPath(row: 3, section: 0):
            self.navigationController?.pushViewController(DarkModeSettingViewController(), animated: true)
            
        case IndexPath(row: 2, section: 1):
            self.navigationController?.pushViewController(MemoViewController(memoVCType: .trash, selectedCategoryEntity: nil), animated: true)
        case IndexPath(row: 3, section: 1):
            let alertCon = UIAlertController(
                title: "휴지통 비우기".localized(),
                message: "휴지통의 모든 메모가 삭제됩니다.\n이 동작은 취소할 수 없습니다.".localized(),
                preferredStyle: UIAlertController.Style.actionSheet)
            let deleteAction = UIAlertAction(
                title: "휴지통 비우기".localized(),
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
                title: "취소".localized(),
                style: UIAlertAction.Style.cancel,
                handler: { [weak self] action in
                    guard let self else { fatalError() }
                    self.settingsTableView.reloadRows(at: [indexPath, IndexPath(row: indexPath.row - 1, section: indexPath.section)], with: UITableView.RowAnimation.automatic)
                })
            alertCon.addAction(deleteAction)
            alertCon.addAction(cancelAction)
            self.present(alertCon, animated: true)
            
//        case IndexPath(row: 0, section: 2):
//            let copiedMemoDetailVC = UIViewController()
//            copiedMemoDetailVC.view = MemoDetailViewCopied()
//            copiedMemoDetailVC.title = "테스트"
//            
//            let standardAppearance: UINavigationBarAppearance = {
//                let appearance = UINavigationBarAppearance()
//                appearance.configureWithDefaultBackground()
//                return appearance
//            }()
//            
//            copiedMemoDetailVC.navigationItem.largeTitleDisplayMode = .never
//            copiedMemoDetailVC.navigationController?.navigationBar.standardAppearance = standardAppearance
//            
//            let copiedMemoDetailNaviCon = UINavigationController(rootViewController: copiedMemoDetailVC)
//            self.tabBarController?.present(copiedMemoDetailNaviCon, animated: true)
            
        default:
            return
        }
        
    }
    
    
    
    
    
    
    
}
