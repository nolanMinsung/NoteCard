//
//  CreateCategoryViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit
import Shared

class CreateCategoryViewController: UIViewController {
    
    let categoryManager = CategoryEntityManager.shared
    
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
        print(text)
        guard text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) != "" else {
            
            let alertCon = UIAlertController(title: L10n.CreateCategory.emptyCategoryName, message: L10n.CreateCategory.emptyCategoryNameMessage, preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: L10n.Common.ok, style: UIAlertAction.Style.cancel)
            alertCon.addAction(okAction)
            self.present(alertCon, animated: true)
            
            return
        }
        
        Task {
            do {
                // try categoryManager.createCategoryEntity(withName: text)
                try await CategoryEntityRepository.shared.create(name: text.trimmingCharacters(in: .whitespacesAndNewlines))
                onCategoryCreated?()
                dismiss(animated: true)
            } catch CoreDataError.duplicateCategoryDetected {
                let alertCon = UIAlertController(title: L10n.CategoryList.duplicateName, message: L10n.CategoryList.duplicateNameMessage, preferredStyle: UIAlertController.Style.actionSheet)
                let okAction = UIAlertAction(title: "확인", style: UIAlertAction.Style.cancel)
                alertCon.addAction(okAction)
                self.present(alertCon, animated: true)
                return
            } catch {
                print(error.localizedDescription)
            }
        }
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

