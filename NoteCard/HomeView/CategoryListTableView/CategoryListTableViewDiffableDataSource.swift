//
//  CategoryListTableViewDiffableDataSource.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/21.
//

import UIKit

class CategoryListTableViewDiffableDataSource: UITableViewDiffableDataSource<CategoryListTableViewSection, CategoryEntity> {
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
}
