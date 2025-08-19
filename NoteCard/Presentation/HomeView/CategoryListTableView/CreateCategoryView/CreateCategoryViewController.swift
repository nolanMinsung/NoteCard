//
//  CreateCategoryViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class CreateCategoryViewController: UIViewController {
    
    let categoryManager = CategoryEntityManager.shared
    
    let createCategoryView = CreateCategoryView()
    lazy var categoryNameTextField = createCategoryView.categoryNameTextField
    
    let doneBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem()
        item.title = "완료".localized()
        return item
    }()
    
    let cancelBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem()
        item.title = "취소".localized()
        return item
    }()
    
    
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
        self.title = "카테고리 생성".localized()
        
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
            
            let alertCon = UIAlertController(title: "카테고리 이름이 비었습니다.".localized(), message: "카테고리 이름을 입력하여 카테고리를 추가하세요.".localized(), preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "확인".localized(), style: UIAlertAction.Style.cancel)
            alertCon.addAction(okAction)
            self.present(alertCon, animated: true)
            
            return
        }
        
        do {
            try categoryManager.createCategoryEntity(withName: text)
        } catch {
            print(error.localizedDescription)
            let alertCon = UIAlertController(title: "이름 중복".localized(), message: "같은 이름의 카테고리가 있습니다. 다른 이름을 입력해주세요.".localized(), preferredStyle: UIAlertController.Style.actionSheet)
            let okAction = UIAlertAction(title: "확인", style: UIAlertAction.Style.cancel)
            alertCon.addAction(okAction)
            self.present(alertCon, animated: true)
            return
        }
        
        self.dismiss(animated: true) {
            NotificationCenter.default.post(name: NSNotification.Name("didCreateNewCategoryNotification"), object: nil)
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

