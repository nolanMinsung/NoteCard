//
//  DateTimeFormatSettingViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/12/27.
//

import UIKit
import Data
import Domain
import DesignSystem
import Shared

final class TimeFormatSettingViewController: UIViewController {
    
    let dataSource = [L10n.Settings.format24h]
    
    lazy var timeFormatSettingView = self.view as! TimeFormatSettingView
    lazy var timeFormatSettingTableView = self.timeFormatSettingView.timeFormatSettingTableView
    
    override func loadView() {
        self.view = TimeFormatSettingView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDelegates()
        setupNaviBar()
    }
    
    private func setupDelegates() {
        self.timeFormatSettingTableView.dataSource = self
        self.timeFormatSettingTableView.delegate = self
    }
    
    private func setupNaviBar() {
        self.title = L10n.Settings.timeFormat
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.navigationBar.tintColor = .currentTheme
    }
    
}


extension TimeFormatSettingViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TimeFormatSettingTableViewCell.cellID, for: indexPath) as? TimeFormatSettingTableViewCell else { fatalError("cell dequeuing failed!") }
        cell.configureCell(image: UIImage(systemName: "clock"), text: self.dataSource[indexPath.row])
        return cell
    }
    
}

extension TimeFormatSettingViewController: UITableViewDelegate {
    
}
