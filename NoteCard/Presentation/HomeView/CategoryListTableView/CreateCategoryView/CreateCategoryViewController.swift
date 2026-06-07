//
//  CreateCategoryViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit
import Data
import Domain
import DesignSystem
import Shared

class CreateCategoryViewController: UIViewController {

    let createCategoryView = CreateCategoryView()
    lazy var categoryNameTextField = createCategoryView.categoryNameTextField
    
    let doneBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem()
        item.title = L10n.Common.done
        return item
    }()
    
    let cancelBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem()
        item.title = L10n.Common.cancel
        return item
    }()
    
    var onCategoryCreated: (() -> Void)? = nil

    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = self.createCategoryView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDelegates()
        setupNaviBar()
        setupButtonsAction()
    }
    
    
    private func setupDelegates() {
        self.categoryNameTextField.delegate = self
    }
    
    
    private func setupNaviBar() {
        self.title = L10n.CreateCategory.createCategoryTitle
        
        let appearanceForStandard: UINavigationBarAppearance = {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            return appearance
        }()
        
        self.navigationController?.navigationBar.tintColor = .currentTheme
        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.navigationController?.navigationBar.standardAppearance = appearanceForStandard
        
        self.navigationItem.rightBarButtonItem = doneBarButtonItem
        self.navigationItem.leftBarButtonItem = cancelBarButtonItem
    }
    
    private func setupButtonsAction() {
        self.doneBarButtonItem.target = self
        self.doneBarButtonItem.action = #selector(createCategoryDone)
        
        self.cancelBarButtonItem.target = self
        self.cancelBarButtonItem.action = #selector(dismissVC)
    }
    
    @objc private func createCategoryDone() {
        self.categoryNameTextField.resignFirstResponder()
        guard let text = self.categoryNameTextField.text else { return }
        let trimmedName = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            let alertCon = UIAlertController(title: L10n.CreateCategory.emptyCategoryName, message: L10n.CreateCategory.emptyCategoryNameMessage, preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: L10n.Common.ok, style: UIAlertAction.Style.cancel)
            alertCon.addAction(okAction)
            self.present(alertCon, animated: true)
            return
        }

        Task { @MainActor in
            do {
                let existingNames = try await environment.categoryRepository
                    .getAllCategories(inOrderOf: .modificationDate, isAscending: false)
                    .map(\.name)
                if existingNames.contains(trimmedName) {
                    presentDuplicateNameConfirm(name: trimmedName)
                } else {
                    try await createAndDismiss(name: trimmedName)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    private func presentDuplicateNameConfirm(name: String) {
        let alert = UIAlertController(
            title: L10n.CategoryList.createDuplicateNameConfirm,
            message: L10n.CategoryList.createDuplicateNameConfirmMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.CategoryList.createDuplicateNameProceed, style: .default) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                do {
                    try await self.createAndDismiss(name: name)
                } catch {
                    print(error.localizedDescription)
                }
            }
        })
        self.present(alert, animated: true)
    }

    private func createAndDismiss(name: String) async throws {
        try await environment.categoryRepository.create(name: name)
        onCategoryCreated?()
        dismiss(animated: true)
    }
    
    //category생성을 취소했을 때
    @objc private func dismissVC() {
        self.dismiss(animated: true)
    }
    
}


extension CreateCategoryViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
}

