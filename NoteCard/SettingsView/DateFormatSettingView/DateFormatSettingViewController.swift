//
//  DateTimeFormatSettingViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/12/27.
//

import UIKit

final class DateFormatSettingViewController: UIViewController {
    
    let dateFormatsArray = [
        "yyyy. M. d. (EEE)",
        "M. d. yyyy. (EEE)",
        "d. M. yyyy. (EEE)",
        "yyyy/M/d (EEE)",
        "M/d/yyyy (EEE)",
        "d/M/yyyy (EEE)"
    ]
    
    
    lazy var dateFormatSettingView = self.view as! DateFormatSettingView
    lazy var dateFormatSettingTableView = self.dateFormatSettingView.dateFormatSettingTableView
    
    override func loadView() {
        self.view = DateFormatSettingView()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDelegates()
        setupNaviBar()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        guard let dateFormat = UserDefaults.standard.string(forKey: KeysForUserDefaults.dateFormat.rawValue) else { fatalError() }
//        guard let indexRowToSelect = self.dateFormatsArray.firstIndex(where: { $0 == dateFormat }) else { fatalError() }
//        self.dateFormatSettingTableView.selectRow(at: IndexPath(row: indexRowToSelect, section: 0), animated: false, scrollPosition: .none)
    }
    
    private func setupDelegates() {
        self.dateFormatSettingTableView.dataSource = self
        self.dateFormatSettingTableView.delegate = self
    }
    
    private func setupNaviBar() {
        self.title = "날짜 표시 형식".localized()
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.navigationBar.tintColor = .currentTheme
    }
    
    
}



extension DateFormatSettingViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dateFormatsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DateFormatSettingTableViewCell.cellID, for: indexPath) as? DateFormatSettingTableViewCell else { fatalError("cell dequeuing failed!") }
        guard let exampleDate = Calendar.current.date(from: DateComponents(year: 2007, month: 1, day: 9)) else { fatalError() }
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.dateFormat = self.dateFormatsArray[indexPath.row]
            return formatter
        }()
        let formatExample = dateFormatter.string(from: exampleDate)
        cell.label.text = formatExample
        return cell
    }
    
}

extension DateFormatSettingViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? DateFormatSettingTableViewCell else { fatalError() }
        cell.isSelected = true
        UserDefaults.standard.setValue(dateFormatsArray[indexPath.row], forKey: UserDefaultsKeys.dateFormat.rawValue)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? DateFormatSettingTableViewCell else { fatalError() }
        cell.isSelected = false
    }
    
}
