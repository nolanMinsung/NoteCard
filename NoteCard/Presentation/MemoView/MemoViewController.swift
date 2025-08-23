//
//  MemoViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

import Wisp

enum MemoVCType {
    case category
    case uncategorized
    case favorite
    case all
    case trash
}


class MemoViewController: UIViewController {
    
    let memoVCType: MemoVCType
    let memoEntityManager = MemoEntityManager.shared
    let categoryEntityManager = CategoryEntityManager.shared
    private let appearingToolbarAnimator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1)
    private let disappearingToolbarAnimator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1)
    
    //카테고리가 사라질 경우 카테고리가 없는 메모들도 볼 수 있어야 하므로 selectedCategoryEntity 속성은 옵셔널 타입으로 설정함.
    var selectedCategoryEntity: CategoryEntity?
    var isCategoryNameChanged: Bool = true
    var userDefaultCriterion: String? { return UserDefaults.standard.string(forKey: UserDefaultsKeys.orderCriterion.rawValue) }
    
    lazy var memoView = self.view as! MemoView
    lazy var smallCardCollectionView = memoView.smallCardCollectionView
    lazy var categoryNameTextField = memoView.categoryNameTextField
    
    var memoEntitiesArray: [MemoEntity] = []
    
    lazy var plusBarButtonItem: UIBarButtonItem = { [weak self] in
        guard let self else { fatalError() }
        let barButtonItem = UIBarButtonItem()
        barButtonItem.image = UIImage(systemName: "plus")
        barButtonItem.target = self
        barButtonItem.action = #selector(presentMemoMakingVC)
        return barButtonItem
    }()
    
    let flexibleBarButtonItems: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        return barButtonItem
    }()
    
    lazy var deleteBarButtonItem: UIBarButtonItem = { [weak self] in
        guard let self else { fatalError() }
        let item = UIBarButtonItem()
        item.image = UIImage(systemName: "trash")
        item.tintColor = UIColor.systemRed
        item.target = self
        item.action = #selector(deleteEverySelectedMemo)
        return item
    }()
    
    lazy var ellipsisBarButtonItem: UIBarButtonItem = { [weak self] in
        guard let self else { fatalError() }
        let item = UIBarButtonItem()
        item.image = UIImage(systemName: "ellipsis.circle")
        item.target = self
        if self.memoVCType == .trash {
            item.menu = UIMenu(children: [self.batchAddCategoryMenuAction, self.restoreMemoAction])
        } else {
            item.menu = UIMenu(children: [
                self.batchRemoveCategoryMenuAction,
                self.batchAddCategoryMenuAction,
                self.unsetFavoriteMenuAction,
                self.setFavoriteMenuAction
            ])
            
        }
        return item
    }()
    
    lazy var restoreMemoAction: UIAction = { [weak self] in
        guard let self else { fatalError() }
        let action = UIAction(
            title: "카테고리 없는 메모들로 복구".localized(),
            image: UIImage(systemName: "arrow.counterclockwise")?.withTintColor(.currentTheme, renderingMode: UIImage.RenderingMode.alwaysOriginal),
            handler: { [weak self] action in
                guard let self else { fatalError() }
                guard let selectedIndexPaths = self.smallCardCollectionView.indexPathsForSelectedItems else { fatalError() }
                var deletedMemoEntitiesArray: [MemoEntity] = []
                let alertCon = UIAlertController(title: "이 메모들을 복구하시겠습니까?".localized(), message: "복구된 메모들은 '카테고리 없음' 항목에서 확인할 수 있습니다.".localized(), preferredStyle: UIAlertController.Style.alert)
                let cancelAction = UIAlertAction(title: "취소".localized(), style: UIAlertAction.Style.cancel)
                let restoreAction = UIAlertAction(title: "복구".localized(), style: UIAlertAction.Style.default) { [weak self] action in
                    guard let self else { fatalError() }
                    guard self.smallCardCollectionView.isEditing else { fatalError("memoFlowCollectioniew is not in editing mode") }
                    
//                    if let selectedIndexPaths = self.smallCardCollectionView.indexPathsForSelectedItems {
                        let memoEntitiesArray = self.memoEntitiesArray
                        selectedIndexPaths.forEach { [weak self] indexPath in
                            guard let self else { fatalError() }
//                            guard let selectedCell = self.smallCardCollectionView.cellForItem(at: indexPath) as? SmallCardCollectionViewCell else { return }
                            let memoEntityToDelete = memoEntitiesArray[indexPath.row]
                            deletedMemoEntitiesArray.append(memoEntityToDelete)
                            MemoEntityManager.shared.restoreMemo(memoEntityToDelete)
                            print(indexPath.row, "인덱스 메모 복구함")
                        }
                        NotificationCenter.default.post(name: NSNotification.Name("memoRecoveredToUncategorizedNotification"), object: nil, userInfo: ["recoveredMemos": deletedMemoEntitiesArray])
//                    }
                    
                    
                    self.updateDataSource()
                    self.smallCardCollectionView.deleteItems(at: selectedIndexPaths)
//                    self.reloadAll()
                    
                }
                alertCon.addAction(cancelAction)
                alertCon.addAction(restoreAction)
                self.present(alertCon, animated: true)
                print("핳")
            })
        return action
    }()
    
    
    
    lazy var batchAddCategoryMenuAction: UIAction = { [weak self] in
        guard let self else { fatalError() }
        let action = UIAction(
            title: self.memoVCType == .trash ? "복구할 카테고리 선택".localized() : "카테고리 일괄 추가".localized(),
            image: self.memoVCType == .trash || self.memoVCType == .uncategorized 
            ? UIImage(systemName: "tag")?.withTintColor(.label, renderingMode: UIImage.RenderingMode.alwaysOriginal)
            : UIImage(systemName: "tag")?.withTintColor(.currentTheme, renderingMode: UIImage.RenderingMode.alwaysOriginal)
        ) { [weak self] action in
            guard let self else { fatalError() }
            //여기에 선택된 메모들에 일괄적으로 추가할 카테고리 띄운 후에 선택할 수 있게끔
            
            let categorySelectionVC = CategorySelectionViewController(selectionType: .toAppend)
            let naviCon = UINavigationController(rootViewController: categorySelectionVC)
            
            naviCon.modalPresentationStyle = .pageSheet
            self.present(naviCon, animated: true)
        }
        return action
    }()
    
    
    lazy var batchRemoveCategoryMenuAction: UIAction = { [weak self] in
        guard let self else { fatalError() }
        let action = UIAction(
            title: "카테고리 일괄 해제".localized(),
            image: self.memoVCType == .trash || self.memoVCType == .uncategorized
            ? UIImage(systemName: "tag")?.withTintColor(.label, renderingMode: UIImage.RenderingMode.alwaysOriginal)
            : UIImage(systemName: "tag")?.withTintColor(.currentTheme, renderingMode: UIImage.RenderingMode.alwaysOriginal)
        ) { [weak self] action in
            guard let self else { fatalError() }
            
            let categorySelectionVC = CategorySelectionViewController(selectionType: .toRemove)
            let naviCon = UINavigationController(rootViewController: categorySelectionVC)
            
            naviCon.modalPresentationStyle = .pageSheet
            self.present(naviCon, animated: true)
        }
        return action
    }()
    
    
    lazy var setFavoriteMenuAction: UIAction = { [weak self] in
        guard let self else { fatalError() }
        let action = UIAction(
            title: "즐겨찾기에 추가".localized(),
            image: UIImage(systemName: "heart")?.withTintColor(.systemRed, renderingMode: UIImage.RenderingMode.alwaysOriginal)
        ) { [weak self] action in
            guard let self else { fatalError() }
            guard self.smallCardCollectionView.isEditing else { fatalError("memoFlowCollectioniew is not in editing mode") }
            
            if let selectedIndexPaths = self.smallCardCollectionView.indexPathsForSelectedItems {
                selectedIndexPaths.forEach { indexPath in
                    let selectedMemoEntity = self.memoEntitiesArray[indexPath.item]
                    MemoEntityManager.shared.setFavorite(of: selectedMemoEntity, to: true)
                }
            }
            self.setEditing(false, animated: true)
        }
        return action
    }()
    
    lazy var unsetFavoriteMenuAction: UIAction = { [weak self] in
        guard let self else { fatalError() }
        let action = UIAction(
            title: "즐겨찾기에 해제".localized(),
            image: UIImage(systemName: "heart.slash")?.withTintColor(.systemRed, renderingMode: UIImage.RenderingMode.alwaysOriginal)
        ) { [weak self] action in
            guard let self else { fatalError() }
            guard self.smallCardCollectionView.isEditing else { fatalError("memoFlowCollectioniew is not in editing mode") }
            
            if let selectedIndexPaths = self.smallCardCollectionView.indexPathsForSelectedItems {
                selectedIndexPaths.forEach { indexPath in
                    let selectedMemoEntity = self.memoEntitiesArray[indexPath.item]
                    MemoEntityManager.shared.setFavorite(of: selectedMemoEntity, to: false)
                }
            }
            
            if memoVCType == .favorite {
                guard let selectedIndexPaths = self.smallCardCollectionView.indexPathsForSelectedItems else { fatalError() }
                self.updateDataSource()
                self.smallCardCollectionView.deleteItems(at: selectedIndexPaths)
            }
            
            self.setEditing(false, animated: true)
        }
        return action
    }()
    
    
    
    var labelBarButtonItem: UIBarButtonItem {
        let label = UILabel()
        label.textColor = .label
        label.numberOfLines = 1
//        label.text = "\(self.smallCardCollectionView.indexPathsForSelectedItems?.count ?? 0)개의 메모 선택됨"
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.text = String(format: "%d개의 메모 선택됨".localized(), self.smallCardCollectionView.indexPathsForSelectedItems?.count ?? 0)
        let item = UIBarButtonItem(customView: label)
        return item
    }
    
    
    //    init(selectedCategoryEntity: CategoryEntity?) {
    /// MemoViewController의 생성자
    /// - Parameters:
    ///   - memoVCType: MemoViewController가 어떤 타입일지 결정. 특정 카테고리의 타입, 카테고리가 없는 타입, 즐겨찾기 타입이 있음.
    ///   - selectedCategoryEntity: memoVCType 매개변수에 .category 가 할당됐을 경우, 보여주고자 하는 카테고리.  memoVCType 매개변수에 .category 를 제외한 다른 값이 할당되면 이 매개변수에 어떤 값이 들어와도 해당 카테고리를 보여주지 않는다. 
    init(memoVCType: MemoVCType, selectedCategoryEntity: CategoryEntity? = nil) {
        
        switch memoVCType {
        case .category:
            self.memoVCType = .category
            self.selectedCategoryEntity = selectedCategoryEntity
        case .uncategorized:
            self.memoVCType = .uncategorized
        case .favorite:
            self.memoVCType = .favorite
        case .all:
            self.memoVCType = .all
        case .trash:
            self.memoVCType = .trash
        }
        
        super.init(nibName: nil, bundle: nil)
        self.setupCategoryNameTextField()
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print(#function)
    }
    
    override func loadView() {
        self.view = MemoView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDelegates()
        setupActions()
        setupObservers()
        self.reloadAll()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let keyWindow = UIWindow.current else { fatalError() }
        keyWindow.backgroundColor = .clear
        
        setupNaviBar()
        
//        self.reloadAll()
        
        if self.memoEntitiesArray.count == 0 {
            self.editButtonItem.isEnabled = false
        } else {
            self.editButtonItem.isEnabled = true
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print(#function)
        super.viewWillDisappear(animated)
        
        guard let keyWindow = UIWindow.current else { fatalError() }
        keyWindow.backgroundColor = .systemGray6
        
//        self.setEditing(false, animated: true)
        self.categoryNameTextField.resignFirstResponder()
        self.navigationController?.isToolbarHidden = true
        self.navigationController?.toolbar.alpha = 0
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard let keyWindow = UIWindow.current else { fatalError() }
        keyWindow.backgroundColor = .clear
    }
    
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        print(#function, editing)
        super.setEditing(editing, animated: animated)
        
        guard let naviCon = self.navigationController else { return }
        
        self.smallCardCollectionView.isEditing = editing
        self.smallCardCollectionView.delaysContentTouches = editing
        
        self.editButtonItem.title = editing ? "완료".localized() : "선택".localized()
        
        switch editing {
        case true:
            self.tabBarController?.tabBar.clipsToBounds = true
            if self.memoVCType == .category {
                self.categoryNameTextField.isEnabled = false
            }
            self.disappearingToolbarAnimator.stopAnimation(true)
            
            self.smallCardCollectionView.reconfigureItems(at: self.smallCardCollectionView.indexPathsForVisibleItems)
            self.smallCardCollectionView.visibleCells.forEach { cell in
                cell.layoutSubviews()
            }
            
            self.setToolbarItems([
                self.flexibleBarButtonItems, 
                self.labelBarButtonItem,
                self.flexibleBarButtonItems,
                self.deleteBarButtonItem,
                self.ellipsisBarButtonItem
            ], animated: true)
            
            appearingToolbarAnimator.addAnimations { [weak self] in
                guard let self else { fatalError() }
                naviCon.isToolbarHidden = false
                self.memoView.layoutIfNeeded()
            }
            
            appearingToolbarAnimator.startAnimation()
            
            self.plusBarButtonItem.isEnabled = false
            self.deleteBarButtonItem.isEnabled = false
            self.ellipsisBarButtonItem.isEnabled = false
            
//            self.feedbackGenerator = UIImpactFeedbackGenerator(style: UIImpactFeedbackGenerator.FeedbackStyle.rigid)
//            self.feedbackGenerator.prepare()
            
        case false:
            self.tabBarController?.tabBar.clipsToBounds = false
            if self.memoVCType == .category {
                self.categoryNameTextField.isEnabled = true
            }
            self.appearingToolbarAnimator.stopAnimation(true)
            
            self.smallCardCollectionView.reconfigureItems(at: self.smallCardCollectionView.indexPathsForVisibleItems)
            
            disappearingToolbarAnimator.addAnimations { [weak self] in
                guard let self else { fatalError() }
                naviCon.isToolbarHidden = true
                self.memoView.layoutIfNeeded()
            }
            disappearingToolbarAnimator.startAnimation()
            
            self.plusBarButtonItem.isEnabled = true
//            self.feedbackGenerator = nil
        }
    }
    
    /// title을 표시하는 label의 text에 해당 카테고리의 이름을 할당.
    /// 카테고리가 없을 경우, "카테고리 없음"이라고 표시
    private func setupCategoryNameTextField() {
        switch self.memoVCType {
        case .category:
            self.memoView.categoryNameTextField.text = selectedCategoryEntity?.name
        case .uncategorized:
            self.memoView.categoryNameTextField.text = "카테고리 없음".localized()
            self.categoryNameTextField.isEnabled = false
        case .favorite:
            self.memoView.categoryNameTextField.text = "즐겨찾기한 메모".localized()
            self.categoryNameTextField.isEnabled = false
        case .all:
            self.memoView.categoryNameTextField.text = "전체 메모 목록".localized()
            self.categoryNameTextField.isEnabled = false
        case .trash:
            self.memoView.categoryNameTextField.text = "휴지통".localized()
            self.categoryNameTextField.isEnabled = false
        }
    }
    
    private func setupNaviBar() {
        self.navigationItem.largeTitleDisplayMode = UINavigationItem.LargeTitleDisplayMode.never
        
        if self.memoVCType != .favorite && self.memoVCType != .trash {
            self.navigationItem.rightBarButtonItems = [self.plusBarButtonItem, self.editButtonItem]
        }
        
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
        self.setToolbarItems([self.flexibleBarButtonItems, self.labelBarButtonItem, self.flexibleBarButtonItems, self.deleteBarButtonItem, self.ellipsisBarButtonItem], animated: animated)
    }
    
    @objc private func presentMemoMakingVC() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
        self.view.endEditing(true)
        let memoMakingVC = MemoMakingViewController(category: selectedCategoryEntity)
        appDelegate.memoMakingVC = memoMakingVC
        let naviCon = UINavigationController(rootViewController: memoMakingVC)
        self.present(naviCon, animated: true)
    }
    
    @objc private func deleteEverySelectedMemo() {
        guard self.smallCardCollectionView.isEditing else { return }
        guard let selectedIndexPaths = self.smallCardCollectionView.indexPathsForSelectedItems else { return }
        
        var memoEntitiesToDelete: [MemoEntity] = []
        
        print(selectedIndexPaths)
        let alertCon: UIAlertController
        if self.memoVCType == .trash {
            alertCon = UIAlertController(title: "선택한 메모들을 영구적으로 삭제하시겠습니까?".localized(), message: "이 동작은 취소할 수 없습니다.".localized(), preferredStyle: UIAlertController.Style.actionSheet)
        } else {
            alertCon = UIAlertController(title: "선택된 메모 삭제".localized(), message: "선택한 메모들을 모두 삭제하시겠습니까?".localized(), preferredStyle: UIAlertController.Style.alert)
        }
        alertCon.view.tintColor = .currentTheme
        let cancelAction = UIAlertAction(title: "취소".localized(), style: UIAlertAction.Style.cancel)
        let deleteAction = UIAlertAction(title: "삭제".localized(), style: UIAlertAction.Style.destructive) { [weak self] action in
            guard let self else { fatalError() }
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
    
    private func setupDelegates() {
        self.smallCardCollectionView.dataSource = self
        self.smallCardCollectionView.delegate = self
        self.categoryNameTextField.delegate = self
    }
    
    private func setupActions() {
        self.categoryNameTextField.addTarget(self, action: #selector(categoryNameTextFieldChanged), for: UIControl.Event.editingChanged)
    }
    
    @objc private func categoryNameTextFieldChanged() {
        print(#function)
        self.isCategoryNameChanged = true
    }
    
    //이 메서드는 MemoViewController의 뷰컨트롤러 생애 주기 동안 단 한 번만 블리는 메서드이다.
    //그래서 MemoViewController를 탭해서 열 때 한 번만 불릴 줄 알았는데, 보니까 탭바의 두번째 탭으로 MemoViewController가 기본으로 들어가며(SceneDelegate에서 할당) 이때 MemoViewController 인스턴스가 생성되므로
    //당연히 이 때에도 setupObservers() 메서드가 불린다. 그래서 NotificationCenter에 post 하면 두 번 불리는 것임.
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(memoCreated(_:)), name: NSNotification.Name("createdMemoNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(memoEdited(_:)), name: NSNotification.Name("editingCompleteNotification"), object: nil)
        
        if self.memoVCType == MemoVCType.uncategorized {
            NotificationCenter.default.addObserver(self, selector: #selector(memoRecoveredToUncategorized(_:)), name: NSNotification.Name("memoRecoveredToUncategorizedNotification"), object: nil)
            print("복구 notification 추가됨")
        }
    }
    
    //메모가 추가된 후 Notification을 받았을 때 실행할 함수
    @objc private func memoCreated(_ notification: Notification) {
        print(#function)
        print(self)
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
    
    @objc private func memoEdited(_ notification: Notification) {
        print(#function)
        guard let editedMemoEntity = notification.userInfo?["memo"] as? MemoEntity else { fatalError() }
        
        if self.memoEntitiesArray.contains(editedMemoEntity) {
            guard let indexToReload = self.memoEntitiesArray.firstIndex(of: editedMemoEntity) else { fatalError() }
            
        } else {
            return
        }
        
        self.setupToolbar()
    }
    
    @objc private func memoRecoveredToUncategorized(_ notification: Notification) {
        print("uncategorized MemoVC에서 메모 복구 Notification 받았다!!")
        guard let recoveredMemo = notification.userInfo?["recoveredMemos"] as? [MemoEntity] else { fatalError() }
        
        self.reloadAll()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    
    private func reloadAll() {
        print(#function)
        self.updateDataSource()
        self.smallCardCollectionView.reloadData()
    }
    
    private func presentPopupCardVC(at indexPath: IndexPath, inset: UIEdgeInsets) {
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
        self.setupToolbar(animated: false)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard collectionView == self.smallCardCollectionView else { return }
        self.setupToolbar(animated: false)
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
