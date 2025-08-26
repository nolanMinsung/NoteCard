//
//  MemoViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

import Wisp

class MemoViewController: UIViewController {
    
    enum MemoVCType: Equatable {
        case category(selectedCategory: CategoryEntity?)
        case uncategorized
        case favorite
        case all
        case trash
        
        var initialCategoryTitle: String? {
            switch self {
            case .category(let category):    category?.name
            case .uncategorized:             "카테고리 없음".localized()
            case .favorite:                  "즐겨찾기한 메모".localized()
            case .all:                       "전체 메모 목록".localized()
            case .trash:                     "휴지통".localized()
            }
        }
        
        var isCategory: Bool {
            switch self {
            case .category:
                true
            default:
                false
            }
        }
    }
    
    let memoVCType: MemoVCType
    let memoEntityManager = MemoEntityManager.shared
    let categoryEntityManager = CategoryEntityManager.shared
    
    //카테고리가 사라질 경우 카테고리가 없는 메모들도 볼 수 있어야 하므로 selectedCategoryEntity 속성은 옵셔널 타입으로 설정함.
    var selectedCategoryEntity: CategoryEntity?
    private var isCategoryNameChanged: Bool = true
    private var userDefaultCriterion: String? { return UserDefaults.standard.string(forKey: UserDefaultsKeys.orderCriterion.rawValue) }
    
    private lazy var rootView = self.view as! MemoView
    private lazy var categoryNameTextField = rootView.categoryNameTextField
    lazy var smallCardCollectionView = rootView.smallCardCollectionView
    
    var memoEntitiesArray: [MemoEntity] = []
    
    // navigationItems
    private let plusBarButtonItem = UIBarButtonItem()
    
    // (bottom) tool bar Items
    private let labelBarButtonItem = UIBarButtonItem()
    private let flexibleBarButtonItems = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    private let deleteBarButtonItem = UIBarButtonItem()
    private let ellipsisBarButtonItem = UIBarButtonItem()
    
    private var restoreMemoAction: UIAction!
    private var batchAddCategoryMenuAction: UIAction!
    private var batchRemoveCategoryMenuAction: UIAction!
    private var setFavoriteMenuAction: UIAction!
    private var unsetFavoriteMenuAction: UIAction!
    
    //    init(selectedCategoryEntity: CategoryEntity?) {
    /// MemoViewController의 생성자
    /// - Parameters:
    ///   - memoVCType: MemoViewController가 어떤 타입일지 결정. 특정 카테고리의 타입, 카테고리가 없는 타입, 즐겨찾기 타입이 있음.
    ///   - selectedCategoryEntity: memoVCType 매개변수에 .category 가 할당됐을 경우, 보여주고자 하는 카테고리.  memoVCType 매개변수에 .category 를 제외한 다른 값이 할당되면 이 매개변수에 어떤 값이 들어와도 해당 카테고리를 보여주지 않는다. 
    init(memoVCType: MemoVCType) {
        
        self.memoVCType = memoVCType
        
        if case let .category(selectedCategoryEntity) = memoVCType {
            self.selectedCategoryEntity = selectedCategoryEntity
        }
        super.init(nibName: nil, bundle: nil)
        
        self.rootView.categoryNameTextField.text = memoVCType.initialCategoryTitle
        self.rootView.categoryNameTextField.isEnabled = memoVCType.isCategory
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = MemoView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNaviBar()
        setupToolbar()
        setupBarButtonActions()
        setupBarButtonItems()
        setupDelegates()
        setupActions()
        setupObservers()
        reloadAll()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        UIView.springAnimate(withDuration: 0.4) { [weak self] in
            self?.navigationController?.isToolbarHidden = !editing
            self?.rootView.layoutIfNeeded()
        }
        self.smallCardCollectionView.isEditing = editing
        self.smallCardCollectionView.delaysContentTouches = editing
        self.categoryNameTextField.isEnabled = (!editing && memoVCType.isCategory)
        // editnButtonItem 의 기본 구현이라서 굳이 필요 없는 듯...?
//        self.editButtonItem.title = editing ? "완료".localized() : "선택".localized()
        
        switch editing {
        case true:
            self.smallCardCollectionView.reconfigureItems(at: self.smallCardCollectionView.indexPathsForVisibleItems)
            self.smallCardCollectionView.visibleCells.forEach { cell in
                cell.layoutSubviews()
            }
            
            self.plusBarButtonItem.isEnabled = false
            self.deleteBarButtonItem.isEnabled = false
            self.ellipsisBarButtonItem.isEnabled = false
            
        case false:
            self.tabBarController?.tabBar.clipsToBounds = false
            self.smallCardCollectionView.reconfigureItems(at: self.smallCardCollectionView.indexPathsForVisibleItems)
            self.plusBarButtonItem.isEnabled = true
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    
}


// MARK: - Initial Settings
private extension MemoViewController {
    
    func setupNaviBar() {
        self.navigationItem.largeTitleDisplayMode = UINavigationItem.LargeTitleDisplayMode.never
        self.navigationItem.rightBarButtonItems = [self.plusBarButtonItem, self.editButtonItem]
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.compactAppearance = appearance
        self.navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
        self.navigationController?.navigationBar.tintColor = .currentTheme
        
        let toolbarAppearance = UIToolbarAppearance()
        toolbarAppearance.configureWithDefaultBackground()
        
        let transparentToolbarAppearance = UIToolbarAppearance()
        transparentToolbarAppearance.configureWithTransparentBackground()
        
        self.navigationController?.toolbar.standardAppearance = toolbarAppearance
        self.navigationController?.toolbar.scrollEdgeAppearance = toolbarAppearance
        self.navigationController?.isToolbarHidden = true
    }
    
    func setupToolbar(animated: Bool = true) {
        setToolbarItems(
            [flexibleBarButtonItems,
             labelBarButtonItem,
             flexibleBarButtonItems,
             deleteBarButtonItem,
             ellipsisBarButtonItem],
            animated: animated
        )
    }
    
    func setupBarButtonActions() {
        restoreMemoAction = UIAction(
            title: "카테고리 없는 메모들로 복구".localized(),
            image: UIImage(systemName: "arrow.counterclockwise")?
                .withTintColor(
                    .currentTheme,
                    renderingMode: .alwaysOriginal
                ),
            handler: { [weak self] action in
                self?.askToRestoreMemo()
            }
        )
        
        let batchUpdateActionTintColor: UIColor = (
            (self.memoVCType == .trash || self.memoVCType == .uncategorized)
            ? .label
            : .currentTheme
        )
        
        batchAddCategoryMenuAction = UIAction(
            title: self.memoVCType == .trash ? "복구할 카테고리 선택".localized() : "카테고리 일괄 추가".localized(),
            image: UIImage(systemName: "tag")?
                .withTintColor(
                    batchUpdateActionTintColor,
                    renderingMode: .alwaysOriginal
                ),
            handler: { [weak self] _ in
                self?.presentCategoriesToAdd()
            }
        )
        
        batchRemoveCategoryMenuAction = UIAction(
            title: "카테고리 일괄 해제".localized(),
            image: UIImage(systemName: "tag")?
                .withTintColor(
                    consume batchUpdateActionTintColor,
                    renderingMode: .alwaysOriginal
                ),
            handler: { [weak self] _ in
                self?.presentCategoriesToRemove()
            }
        )
        
        setFavoriteMenuAction = UIAction(
            title: "즐겨찾기에 추가".localized(),
            image: UIImage(systemName: "heart")?
                .withTintColor(.systemRed, renderingMode: .alwaysOriginal),
            handler: { [weak self] _ in
                self?.likeSelectedMemos()
            }
        )
        
        unsetFavoriteMenuAction = UIAction(
            title: "즐겨찾기에 해제".localized(),
            image: UIImage(systemName: "heart.slash")?
                .withTintColor(.systemRed, renderingMode: .alwaysOriginal),
            handler: { [weak self] _ in
                self?.unlikeFavoriteSelectedMemos()
            }
        )
    }
    
    func setupBarButtonItems() {
        plusBarButtonItem.image = UIImage(systemName: "plus")
        plusBarButtonItem.target = self
        plusBarButtonItem.action = #selector(presentMemoMakingVC)
        
        deleteBarButtonItem.image = UIImage(systemName: "trash")
        deleteBarButtonItem.tintColor = .systemRed
        deleteBarButtonItem.target = self
        deleteBarButtonItem.action = #selector(deleteEverySelectedMemo)
        
        ellipsisBarButtonItem.image = UIImage(systemName: "ellipsis.circle")
        let ellipsisBarButtonItemMenu: UIMenu
        if memoVCType == .trash {
            ellipsisBarButtonItemMenu = UIMenu(children: [
                batchAddCategoryMenuAction,
                restoreMemoAction
            ])
        } else {
            ellipsisBarButtonItemMenu = UIMenu(children: [
                batchRemoveCategoryMenuAction,
                batchAddCategoryMenuAction,
                unsetFavoriteMenuAction,
                setFavoriteMenuAction
            ])
        }
        ellipsisBarButtonItem.menu = ellipsisBarButtonItemMenu
        
        labelBarButtonItem.setTitleTextAttributes(
            [.font: UIFont.systemFont(ofSize: 17, weight: .bold)],
            for: .normal
        )
        labelBarButtonItem.tintColor = .label
        labelBarButtonItem.title = String(
            format: "%d개의 메모 선택됨".localized(),
            smallCardCollectionView.indexPathsForSelectedItems?.count ?? 0
        )
    }
    
    func setupDelegates() {
        self.smallCardCollectionView.dataSource = self
        self.smallCardCollectionView.delegate = self
        self.categoryNameTextField.delegate = self
    }
    
    func setupActions() {
        self.categoryNameTextField.addTarget(
            self,
            action: #selector(categoryNameTextFieldChanged),
            for: UIControl.Event.editingChanged
        )
    }
    
    func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(memoCreated(_:)), name: NSNotification.Name("createdMemoNotification"), object: nil)
        
        if self.memoVCType == MemoVCType.uncategorized {
            NotificationCenter.default.addObserver(self, selector: #selector(memoRecoveredToUncategorized(_:)), name: NSNotification.Name("memoRecoveredToUncategorizedNotification"), object: nil)
            print("복구 notification 추가됨")
        }
    }
    
}

// MARK: - Bar Button Actions
private extension MemoViewController {
    
    func askToRestoreMemo() {
        let alertCon = UIAlertController(
            title: "이 메모들을 복구하시겠습니까?".localized(),
            message: "복구된 메모들은 '카테고리 없음' 항목에서 확인할 수 있습니다.".localized(),
            preferredStyle: UIAlertController.Style.alert
        )
        let restoreAction = UIAlertAction(title: "복구".localized(), style: .default) { [weak self] action in
            guard let self else { return }
            guard self.smallCardCollectionView.isEditing else { return }
            guard let selectedIndexPaths = self.smallCardCollectionView.indexPathsForSelectedItems else { fatalError() }
            let memoEntitiesArray = self.memoEntitiesArray
            selectedIndexPaths.forEach { indexPath in
                let memoEntityToDelete = memoEntitiesArray[indexPath.row]
                MemoEntityManager.shared.restoreMemo(memoEntityToDelete)
                print(indexPath.row, "인덱스 메모 복구함")
            }
            self.updateDataSource()
            self.smallCardCollectionView.deleteItems(at: selectedIndexPaths)
        }
        let cancelAction = UIAlertAction(title: "취소".localized(), style: .cancel)
        alertCon.addAction(restoreAction)
        alertCon.addAction(cancelAction)
        present(alertCon, animated: true)
    }
    
    func presentCategoriesToAdd() {
        let categorySelectionVC = CategorySelectionViewController(selectionType: .toAppend)
        let naviCon = UINavigationController(rootViewController: categorySelectionVC)
        naviCon.modalPresentationStyle = .pageSheet
        present(naviCon, animated: true)
    }
    
    func presentCategoriesToRemove() {
        let categorySelectionVC = CategorySelectionViewController(selectionType: .toRemove)
        let naviCon = UINavigationController(rootViewController: categorySelectionVC)
        naviCon.modalPresentationStyle = .pageSheet
        present(naviCon, animated: true)
    }
    
    func likeSelectedMemos() {
        guard smallCardCollectionView.isEditing else { return }
        guard let selectedIndexPaths = smallCardCollectionView.indexPathsForSelectedItems else {
            return
        }
        selectedIndexPaths.forEach { indexPath in
            let selectedMemoEntity = memoEntitiesArray[indexPath.item]
            MemoEntityManager.shared.setFavorite(of: selectedMemoEntity, to: true)
        }
        self.setEditing(false, animated: true)
    }
    
    func unlikeFavoriteSelectedMemos() {
        guard smallCardCollectionView.isEditing else { return }
        guard let selectedIndexPaths = smallCardCollectionView.indexPathsForSelectedItems else {
            return
        }
        selectedIndexPaths.forEach { indexPath in
            let selectedMemoEntity = memoEntitiesArray[indexPath.item]
            MemoEntityManager.shared.setFavorite(of: selectedMemoEntity, to: false)
        }
        
        if memoVCType == .favorite {
            guard let selectedIndexPaths = self.smallCardCollectionView.indexPathsForSelectedItems else { fatalError() }
            self.updateDataSource()
            self.smallCardCollectionView.deleteItems(at: selectedIndexPaths)
        }
        self.setEditing(false, animated: true)
    }
    
}


private extension MemoViewController {
    
    @objc func presentMemoMakingVC() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
        self.view.endEditing(true)
        let memoMakingVC = MemoMakingViewController(category: selectedCategoryEntity)
        appDelegate.memoMakingVC = memoMakingVC
        let naviCon = UINavigationController(rootViewController: memoMakingVC)
        self.present(naviCon, animated: true)
    }
    
    @objc func deleteEverySelectedMemo() {
        guard self.smallCardCollectionView.isEditing else { return }
        guard let selectedIndexPaths = self.smallCardCollectionView.indexPathsForSelectedItems else { return }
        
        var memoEntitiesToDelete: [MemoEntity] = []
        
        let alertCon: UIAlertController
        if self.memoVCType == .trash {
            alertCon = UIAlertController(
                title: "선택한 메모들을 영구적으로 삭제하시겠습니까?".localized(),
                message: "이 동작은 취소할 수 없습니다.".localized(),
                preferredStyle: UIAlertController.Style.actionSheet
            )
        } else {
            alertCon = UIAlertController(
                title: "선택된 메모 삭제".localized(),
                message: "선택한 메모들을 모두 삭제하시겠습니까?".localized(),
                preferredStyle: UIAlertController.Style.alert
            )
        }
        alertCon.view.tintColor = .currentTheme
        let cancelAction = UIAlertAction(title: "취소".localized(), style: UIAlertAction.Style.cancel)
        let deleteAction = UIAlertAction(title: "삭제".localized(), style: UIAlertAction.Style.destructive) { [weak self] action in
            guard let self else { return }
            selectedIndexPaths.forEach { [weak self] indexPath in
                guard let self else { return }
                
                let selectedMemoEntity = self.memoEntitiesArray[indexPath.item]
                if self.memoVCType == .trash {
                    MemoEntityManager.shared.deleteMemoEntity(memoEntity: selectedMemoEntity)
                } else {
                    MemoEntityManager.shared.trashMemo(selectedMemoEntity)
                    memoEntitiesToDelete.append(selectedMemoEntity)
                }
            }
            
            if self.memoVCType != .trash {
                NotificationCenter.default.post(name: NSNotification.Name("memoTrashedNotification"), object: nil, userInfo: ["trashedMemos": memoEntitiesToDelete])
            }
            
            self.updateDataSource()
            
            self.smallCardCollectionView.deleteItems(at: selectedIndexPaths)
            
            if self.memoEntitiesArray.count == 0 {
                self.setEditing(false, animated: false)
                self.editButtonItem.isEnabled = false
            } else {
                self.setEditing(false, animated: true)
                self.editButtonItem.isEnabled = true
            }
        }
        
        alertCon.addAction(cancelAction)
        alertCon.addAction(deleteAction)
        self.present(alertCon, animated: true)
    }
    
    func makeAlert(title: String, message: String, answer: String, preferredStyle: UIAlertController.Style? = .alert, handler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: preferredStyle!)
        let okAction = UIAlertAction(title: answer, style: .cancel, handler: handler)
        alert.addAction(okAction)
        self.present(alert, animated: true)
    }
    
    @objc func categoryNameTextFieldChanged() {
        self.isCategoryNameChanged = true
    }
    
    //메모가 추가된 후 Notification을 받았을 때 실행할 함수
    @objc func memoCreated(_ notification: Notification) {
        if self.memoEntitiesArray.count != 0 {
            self.editButtonItem.isEnabled = true
        }
        
        guard let createdMemoEntity = notification.userInfo?["memo"] as? MemoEntity else { fatalError() }
        let categories = createdMemoEntity.categories
        let isOrderAscending = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isOrderAscending.rawValue)
        
        switch self.memoVCType {
            
        case .category:
            guard categories.contains(self.selectedCategoryEntity!) else { return }
            if isOrderAscending {
                self.updateDataSource()
//                self.memoEntitiesArray.append(createdMemoEntity)
                self.smallCardCollectionView.insertItems(at: [IndexPath(item: self.smallCardCollectionView.numberOfItems(inSection: 0), section: 0)])
            } else {
                print(self.memoEntitiesArray.count)
                self.updateDataSource()
//                self.memoEntitiesArray.insert(createdMemoEntity, at: 0)
                self.smallCardCollectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
            }
            
        case .uncategorized:
            if categories.count == 0 { //uncategorized일 때 createdMemo.categories.count == 0 이면 return
                if isOrderAscending {
                    //                self.updateDataSource()
                    self.memoEntitiesArray.append(createdMemoEntity)
                    self.smallCardCollectionView.insertItems(at: [IndexPath(item: self.smallCardCollectionView.numberOfItems(inSection: 0), section: 0)])
                } else {
                    print(self.memoEntitiesArray.count)
                    //                self.updateDataSource()
                    self.memoEntitiesArray.insert(createdMemoEntity, at: 0)
                    self.smallCardCollectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
                }
            } else {
                return
            }
            
        case .favorite:
            return
            
        case .all:
            if isOrderAscending {
                self.memoEntitiesArray.append(createdMemoEntity)
                self.smallCardCollectionView.insertItems(at: [IndexPath(item: self.smallCardCollectionView.numberOfItems(inSection: 0), section: 0)])
            } else {
                print(self.memoEntitiesArray.count)
                self.memoEntitiesArray.insert(createdMemoEntity, at: 0)
                self.smallCardCollectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
            }
            
        case .trash:
            return
            
        }
    }
    
    @objc func memoRecoveredToUncategorized(_ notification: Notification) {
        print("uncategorized MemoVC에서 메모 복구 Notification 받았다!!")
        guard let recoveredMemo = notification.userInfo?["recoveredMemos"] as? [MemoEntity] else { fatalError() }
        
        self.reloadAll()
    }
    
    func reloadAll() {
        self.updateDataSource()
        self.smallCardCollectionView.reloadData()
    }
    
    func presentPopupCardVC(at indexPath: IndexPath, inset: UIEdgeInsets) {
        let wispConfiguration = WispConfiguration { config in
            config.setLayout { layout in
                layout.presentedAreaInset = inset
                layout.initialCornerRadius = 13
                layout.finalCornerRadius = 25
            }
            config.setGesture { gesture in
                gesture.allowedDirections = [.horizontalOnly, .down]
            }
        }
        
        let memoEntity = memoEntitiesArray[indexPath.item]
        let popupCardVC = PopupCardViewController(memo: memoEntity, indexPath: .init(item: 0, section: 0))
        wisp.present(
            popupCardVC,
            collectionView: smallCardCollectionView,
            at: indexPath,
            configuration: wispConfiguration
        )
    }
    
}


// MARK: - UICollectionViewDataSource
extension MemoViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.memoEntitiesArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch collectionView {
        case self.smallCardCollectionView:
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SmallCardCollectionViewCell.cellID, for: indexPath) as? SmallCardCollectionViewCell else {
                fatalError("Cell couldn't dequeued")
            }
            cell.configureCell(with: self.memoEntitiesArray[indexPath.item])
            cell.onLongPressSelected = { [weak self] in
                self?.presentPopupCardVC(
                    at: indexPath,
                    inset: .init(top: 100, left: 10, bottom: 100, right: 10)
                )
            }
            cell.opaqueView.alpha = smallCardCollectionView.isEditing ? 0.7 : 0
            return cell
            
        default:
            fatalError()
        }
        
    }
    
}


// MARK: - UICollectionViewDelegate
extension MemoViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if collectionView.isEditing {
            return true
        } else {
            let popupCardTopInset = navigationController?.view.safeAreaInsets.top ?? 0
            presentPopupCardVC(
                at: indexPath,
                inset: .init(top: popupCardTopInset, left: 0, bottom: 0, right: 0)
            )
            return false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard self.smallCardCollectionView.isEditing else { return }
        self.deleteBarButtonItem.isEnabled = true
        self.ellipsisBarButtonItem.isEnabled = true
        labelBarButtonItem.title = String(
            format: "%d개의 메모 선택됨".localized(),
            smallCardCollectionView.indexPathsForSelectedItems?.count ?? 0
        )
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard collectionView == self.smallCardCollectionView else { return }
        labelBarButtonItem.title = String(
            format: "%d개의 메모 선택됨".localized(),
            smallCardCollectionView.indexPathsForSelectedItems?.count ?? 0
        )
        if self.smallCardCollectionView.indexPathsForSelectedItems?.count == 0 {
            self.ellipsisBarButtonItem.isEnabled = false
            self.deleteBarButtonItem.isEnabled = false
        } else {
            self.deleteBarButtonItem.isEnabled = true
            self.ellipsisBarButtonItem.isEnabled = true
        }
    }
    
    func updateDataSource() {
        switch self.memoVCType {
        case .category:
            self.memoEntitiesArray = MemoEntityManager.shared.getSpecificMemoEntitiesFromCoreData(inCategory: self.selectedCategoryEntity)
            
        case .uncategorized:
            self.memoEntitiesArray = MemoEntityManager.shared.getSpecificMemoEntitiesFromCoreData(inCategory: self.selectedCategoryEntity)
            
        case .favorite:
            self.memoEntitiesArray = MemoEntityManager.shared.getFavoriteMemoEntities()
            
        case .all:
            self.memoEntitiesArray = MemoEntityManager.shared.getMemoEntitiesFromCoreData()
            
        case .trash:
            self.memoEntitiesArray = MemoEntityManager.shared.getMemoEntitiesInTrash()
        }
    }
    
}


// MARK: - UITextFieldDelegate
extension MemoViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        guard let newCategoryName = textField.text else { return }
        guard let selectedCategoryEntity else { fatalError("selectedCategoryEntity is nil") }
        
        do {
            try CategoryEntityManager.shared.changeCategoryEntityName(ofEntity: selectedCategoryEntity, newName: newCategoryName)
        } catch {
            print(error.localizedDescription)
            let alertCon = UIAlertController(title: "이름 중복".localized(), message: "같은 이름의 카테고리가 있습니다. 다른 이름을 입력해주세요.".localized(), preferredStyle: UIAlertController.Style.actionSheet)
            let okAction = UIAlertAction(title: "확인", style: UIAlertAction.Style.cancel) { action in
                self.categoryNameTextField.becomeFirstResponder()
            }
            alertCon.addAction(okAction)
            self.present(alertCon, animated: true)
            return
        }
        
        if self.isCategoryNameChanged {
            
            self.reloadAll()
            
            self.isCategoryNameChanged = false
        }
    }
    
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            
            makeAlert(title: "알림".localized(), message: "카테고리 이름을 비울 수 없습니다.".localized(), answer: "확인".localized())
            
            return false
        } else {
            return true
        }
    }
}
