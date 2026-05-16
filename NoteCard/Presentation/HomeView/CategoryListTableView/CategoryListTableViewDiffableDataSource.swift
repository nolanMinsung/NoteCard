//
//  CategoryListTableViewDiffableDataSource.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/21.
//

import UIKit
import Data
import Domain
import DesignSystem
import Shared

class CategoryListTableViewDiffableDataSource: UITableViewDiffableDataSource<CategoryListTableViewSection, Domain.Category> {
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
}
