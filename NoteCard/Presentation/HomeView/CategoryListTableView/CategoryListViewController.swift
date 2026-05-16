//
//  CategoryListTableViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

//
//  CategoryListTableViewController.swift
//  memoText
//
//  Created by 김민성 on 2023/10/02.
//

import UIKit
import Data
import Domain
import DesignSystem
import Shared

enum CategoryListTableViewSection: CaseIterable {
    case main
}

class CategoryListViewController: UITableViewController {
    
    private var memoCountByCategory: [Domain.Category: Int] = [:]
    let addCategoryBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem()
        item.image = UIImage(systemName: "plus")
        return item
    }()
    
    let searchCategoryBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem()
        item.image = UIImage(systemName: "magnifyingglass")
        return item
    }()
    
    let searchController = UISearchController()
    
    var categoryDiffableDataSource: CategoryListTableViewDiffableDataSource!
    var categoryNameChangingTextField: UITextField!
    var saveAction: UIAlertAction!

    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupDiffableDataSource()
        setupNaviBar()
        setupButtonsAction()
        setupDelegates()
        applySnapshot(animatingDifferences: false, usingReloadData: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print(#function)
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.standardAppearance = {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            return appearance
        }()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let searchText = self.searchController.searchBar.searchTextField.text else { fatalError() }
        if searchText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == "" {
            self.applySnapshot(animatingDifferences: false, usingReloadData: true)
        } else {
            self.applySnapshot(searchWith: searchText, animatingDifferences: true, usingReloadData: true)
        }
        
    }
    
    private func setupTableView() {
        self.tableView = {
            let tableView = UITableView(frame: .zero, style: UITableView.Style.insetGrouped)
            tableView.register(CategoryListTableViewCell.self, forCellReuseIdentifier: CategoryListTableViewCell.cellID)
            return tableView
        }()
    }
    
    private func setupDiffableDataSource() {
        self.categoryDiffableDataSource = CategoryListTableViewDiffableDataSource(tableView: self.tableView, cellProvider: { [weak self] tableView, indexPath, category in

            guard let cell = tableView.dequeueReusableCell(withIdentifier: CategoryListTableViewCell.cellID, for: indexPath) as? CategoryListTableViewCell else { fatalError("cell dequeueing failed.") }
            let memoCount = self?.memoCountByCategory[category] ?? 0
            cell.configureCell(with: category, memoCount: memoCount)
            return cell
        })
    }
    
    func applySnapshot(animatingDifferences: Bool, usingReloadData: Bool, completion: (() -> Void)? = nil) {
        Task {
            do {
                let categories = try await environment.categoryRepository.getAllCategories(
                    inOrderOf: .modificationDate,
                    isAscending: false
                )
                try await applySnapshot(
                    with: categories,
                    animatingDifferences: animatingDifferences,
                    usingReloadData: usingReloadData,
                    completion: completion
                )
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    private func applySnapshot(searchWith searchText: String, animatingDifferences: Bool, usingReloadData: Bool, completion: (() -> Void)? = nil) {
        Task {
            do {
                let categories = try await environment.categoryRepository.searchCategory(
                    searchText,
                    inOrderOf: .modificationDate,
                    isAscending: false
                )
                try await applySnapshot(
                    with: categories,
                    animatingDifferences: animatingDifferences,
                    usingReloadData: usingReloadData,
                    completion: completion
                )
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    /// 카테고리별 메모 개수를 조회해 캐시한 뒤 diffable snapshot을 적용한다.
    /// 셀이 표시할 메모 개수(`memoCount`)가 async 조회라 셀에서 직접 못 구하므로,
    /// VC가 미리 모아 `memoCountByCategory`에 담아두고 cellProvider가 읽는다.
    private func applySnapshot(
        with categories: [Domain.Category],
        animatingDifferences: Bool,
        usingReloadData: Bool,
        completion: (() -> Void)?
    ) async throws {
        var counts: [Domain.Category: Int] = [:]
        for category in categories {
            counts[category] = try await environment.categoryRepository.memoCount(of: category)
        }
        self.memoCountByCategory = counts

        var snapshot = NSDiffableDataSourceSnapshot<CategoryListTableViewSection, Domain.Category>()
        snapshot.appendSections([.main])
        snapshot.appendItems(categories, toSection: .main)

        switch usingReloadData {
        case true:
            self.categoryDiffableDataSource.applySnapshotUsingReloadData(snapshot, completion: completion)
        case false:
            self.categoryDiffableDataSource.apply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
        }
    }
    
    private func setupNaviBar() {
        print(#function)
        self.title = L10n.CategoryList.allCategoriesTitle
        
        self.navigationItem.searchController = self.searchController
        self.navigationItem.hidesSearchBarWhenScrolling = true
        self.navigationItem.setRightBarButtonItems([addCategoryBarButtonItem, searchCategoryBarButtonItem], animated: false)
        self.navigationController?.navigationBar.tintColor = UIColor.currentTheme
        self.navigationController?.navigationBar.standardAppearance = {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            return appearance
        }()
        
        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    private func setupButtonsAction() {
        self.addCategoryBarButtonItem.target = self
        self.addCategoryBarButtonItem.action = #selector(presentCreateCategoryVC)
        
        self.searchCategoryBarButtonItem.target = self
        self.searchCategoryBarButtonItem.action = #selector(showSearchBar)
    }
    
    @objc private func presentCreateCategoryVC() {
        let createCategoryVC = CreateCategoryViewController(environment: environment)
        createCategoryVC.onCategoryCreated = { [weak self] in
            guard let self else { return }
            self.categoryCreated()
        }
        let naviCon = UINavigationController(rootViewController: createCategoryVC)
        self.present(naviCon, animated: true)
    }
    
    @objc private func showSearchBar() {
        DispatchQueue.main.async {
            self.searchController.searchBar.becomeFirstResponder()
        }
    }
    
    private func setupDelegates() {
        self.tableView.delegate = self
        self.searchController.searchBar.delegate = self
    }
    
    @objc private func categoryCreated() {
        self.applySnapshot(animatingDifferences: true, usingReloadData: false)
    }
    
    private func makeAlert(title: String, message: String, answer: String, preferredStyle: UIAlertController.Style? = .alert, handler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: preferredStyle!)
        let okAction = UIAlertAction(title: answer, style: .cancel, handler: handler)
        alert.addAction(okAction)
        self.present(alert, animated: true)
    }
    
    @objc private func toggleSaveAction() {
        if self.categoryNameChangingTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            self.saveAction.isEnabled = false
        } else {
            self.saveAction.isEnabled = true
        }
    }
    
}



extension CategoryListViewController {
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.delete
    }
    
    
    //    UITableViewController 되면서 override 함
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let categoryToDelete = categoryDiffableDataSource.itemIdentifier(for: indexPath) else { return }
            Task {
                do {
                    try await environment.categoryRepository.deleteCategory(categoryToDelete)
                    applySnapshot(animatingDifferences: true, usingReloadData: false)
                } catch {
                    print(error.localizedDescription)
                }
            }
        } else if editingStyle == .insert {
            return
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    
//    UITableViewController 되면서 override 함
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard let swipedCell = tableView.cellForRow(at: indexPath) as? CategoryListTableViewCell else { fatalError() }
        guard let selectedCategory = swipedCell.category else { return nil }

        let editNameContextualAction = UIContextualAction(style: UIContextualAction.Style.normal, title: L10n.CategoryList.rename) { [weak self] contextualAction, view, completionHandler in
            guard let self else { return }

            tableView.setEditing(false, animated: true)

            let alertCon = UIAlertController(title: L10n.CategoryList.renameCategory, message: "", preferredStyle: UIAlertController.Style.alert)
            alertCon.addTextField { textField in
                self.categoryNameChangingTextField = textField
                self.categoryNameChangingTextField.placeholder = L10n.CategoryList.enterNewCategoryName
                self.categoryNameChangingTextField.text = selectedCategory.name
                self.categoryNameChangingTextField.addTarget(self, action: #selector(self.toggleSaveAction), for: UIControl.Event.editingChanged)
            }

            self.saveAction = UIAlertAction(title: L10n.Common.save, style: UIAlertAction.Style.destructive) { [weak self] action in
                guard let self else { return }
                guard let newCategoryName = alertCon.textFields?[0].text else { return }
                Task {
                    do {
                        try await self.environment.categoryRepository.changeCategoryName(selectedCategory, newName: newCategoryName)
                        swipedCell.categoryNameLabel.text = newCategoryName
                        self.applySnapshot(animatingDifferences: true, usingReloadData: false)
                    } catch {
                        print(error.localizedDescription)
                        let duplicateAlertCon = UIAlertController(
                            title: L10n.CategoryList.duplicateName,
                            message: L10n.CategoryList.duplicateNameMessage,
                            preferredStyle: UIAlertController.Style.actionSheet
                        )
                        let okAction = UIAlertAction(title: L10n.Common.ok, style: UIAlertAction.Style.cancel) { action in
                            self.navigationController?.present(alertCon, animated: true)
                        }
                        duplicateAlertCon.addAction(okAction)
                        self.present(duplicateAlertCon, animated: true)
                    }
                }
            }
            
            let cancelAction = UIAlertAction(title: L10n.Common.cancel, style: UIAlertAction.Style.cancel) { action in return }
            
            alertCon.addAction(self.saveAction)
            alertCon.addAction(cancelAction)
            
            self.navigationController?.present(alertCon, animated: true)
        }
        
        
        let deleteContextualAction = UIContextualAction(style: UIContextualAction.Style.destructive, title: L10n.Common.delete) { [weak self] contextualAction, view, completionHandler in
            guard let self else { fatalError() }
            
            let alertCon = UIAlertController(
                title: L10n.CategoryList.deleteCategory,
                message: L10n.CategoryList.deleteCategoryConfirm,
                preferredStyle: UIAlertController.Style.alert
            )
            let cancelAction = UIAlertAction(title: L10n.Common.cancel, style: UIAlertAction.Style.cancel) { action in
                completionHandler(true)
            }
            
            let deleteAction = UIAlertAction(title: L10n.Common.delete, style: UIAlertAction.Style.destructive) { [weak self] action in
                guard let self else { fatalError() }
                Task {
                    do {
                        try await self.environment.categoryRepository.deleteCategory(selectedCategory)
                        self.applySnapshot(animatingDifferences: true, usingReloadData: false)
                        completionHandler(true)
                    } catch {
                        print(error.localizedDescription)
                        completionHandler(false)
                    }
                }
            }
            
            alertCon.addAction(cancelAction)
            alertCon.addAction(deleteAction)
            

            self.present(alertCon, animated: true)
            return
        }
        
        let swipeActionsConfiguration = UISwipeActionsConfiguration(actions: [deleteContextualAction, editNameContextualAction])
        swipeActionsConfiguration.performsFirstActionWithFullSwipe = false
        return swipeActionsConfiguration
    }
    
//    UITableViewController 되면서 override 함
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedCategory = categoryDiffableDataSource.itemIdentifier(for: indexPath) else { return }
        let memoVC = MemoViewController(memoVCType: .category(selectedCategory: selectedCategory), environment: environment)
        memoVC.navigationItem.leftBarButtonItem = nil
        self.navigationController?.pushViewController(memoVC, animated: true)
        
    }
    
}

extension CategoryListViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print(#function)
        guard let searchText = searchBar.text else { fatalError() }
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            self.applySnapshot(animatingDifferences: true, usingReloadData: false)
            return
        }
        self.applySnapshot(searchWith: searchText, animatingDifferences: true, usingReloadData: false)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.applySnapshot(animatingDifferences: true, usingReloadData: false)
    }
}
