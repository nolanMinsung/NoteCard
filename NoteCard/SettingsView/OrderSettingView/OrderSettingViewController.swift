//
//  DateTimeFormatSettingViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/12/27.
//

import UIKit




final class OrderSettingViewController: UIViewController {
    
    let dataSource = ["수정 시간".localized(), "만든 시간".localized()]
    let isOrderAscending: Bool = false
    
    
    lazy var orderSettingView = self.view as! OrderSettingView
    lazy var orderSettingTableView = self.orderSettingView.orderSettingTableView
    
    override func loadView() {
        self.view = OrderSettingView()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDelegates()
        setupNaviBar()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let orderCriterion = UserDefaults.standard.string(forKey: UserDefaultsKeys.orderCriterion.rawValue) else { fatalError() }
        guard let indexToSelectAtSection0 = OrderCriterion.allCases.map({ $0.rawValue }).firstIndex(where: { $0 == orderCriterion }) else { fatalError() }
        self.orderSettingTableView.selectRow(at: IndexPath(row: indexToSelectAtSection0, section: 0), animated: false, scrollPosition: .none)
        
        let isOrderAscending = UserDefaults.standard.value(forKey: UserDefaultsKeys.isOrderAscending.rawValue) as! Bool
        let indexToSelectAtSection1 = isOrderAscending ? 0 : 1
        self.orderSettingTableView.selectRow(at: IndexPath(row: indexToSelectAtSection1, section: 1), animated: false, scrollPosition: .none)
    }
    
    private func setupDelegates() {
        self.orderSettingTableView.dataSource = self
        self.orderSettingTableView.delegate = self
    }
    
    private func setupNaviBar() {
        self.title = "메모 순서 표시".localized()
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.navigationBar.tintColor = .currentTheme()
    }
    
    
}



extension OrderSettingViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.dataSource.count
        } else {
            return 2
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderSettingTableViewCell.cellID, for: indexPath) as? OrderSettingTableViewCell else { fatalError("cell dequeuing failed!") }
        
        switch indexPath.section {
        case 0:
            cell.configureCell(text: self.dataSource[indexPath.row])
        case 1:
            if indexPath.row == 0 {
                cell.configureCell(text: "오름차순".localized())
            } else if indexPath.row == 1 {
                cell.configureCell(text: "내림차순".localized())
            }
            
        default:
            fatalError()
        }
        
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "메모 정렬 기준".localized()
        } else {
            return nil
        }
    }
    
    
}

extension OrderSettingViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(tableView.indexPathsForSelectedRows!)
        guard let cell = tableView.cellForRow(at: indexPath) as? OrderSettingTableViewCell else { fatalError() }
        cell.isSelected = true
        if indexPath.section == 0 {
            UserDefaults.standard.setValue(OrderCriterion.allCases[indexPath.row].rawValue, forKey: UserDefaultsKeys.orderCriterion.rawValue)
        } else if indexPath.section == 1 {
            UserDefaults.standard.setValue(indexPath.row == 0 ? true : false, forKey: UserDefaultsKeys.isOrderAscending.rawValue)
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let selectedIndexPaths = tableView.indexPathsForSelectedRows else { fatalError() }
        print(selectedIndexPaths)
        if indexPath.section == 0 {
            selectedIndexPaths.forEach { selectedIndexPath in
                if selectedIndexPath.section == 0, selectedIndexPath.row != indexPath.row {
                    tableView.deselectRow(at: selectedIndexPath, animated: false)
                    guard let cell = tableView.cellForRow(at: selectedIndexPath) as? OrderSettingTableViewCell else { fatalError() }
                    cell.isSelected = false
                }
            }
            return indexPath
            
        } else if indexPath .section == 1 {
            selectedIndexPaths.forEach { selectedIndexPath in
                if selectedIndexPath.section == 1, selectedIndexPath.row != indexPath.row {
                    tableView.deselectRow(at: selectedIndexPath, animated: false)
                    guard let cell = tableView.cellForRow(at: selectedIndexPath) as? OrderSettingTableViewCell else { fatalError() }
                    cell.isSelected = false
                }
            }
            return indexPath
            
        }
        return nil
    }
    
    
    
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let selectedIndexPaths = tableView.indexPathsForSelectedRows else { fatalError() }
        if selectedIndexPaths.contains(indexPath) {
            return nil
        } else {
            return indexPath
        }
    }
    
//    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
//        print(#function)
//        
//        guard let cell = tableView.cellForRow(at: indexPath) as? OrderSettingTableViewCell else { fatalError() }
//        cell.isSelected = false
//    }
    
}
