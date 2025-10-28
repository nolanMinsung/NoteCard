//
//  MemoViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import Combine
import UIKit

import Wisp

class MemoViewController: UIViewController {
    
    enum MemoVCType: Equatable {
        case category(selectedCategory: Category)
        case uncategorized
        case favorite
        case all
        case trash
        
        var initialCategoryTitle: String? {
            switch self {
            case .category(let category):    category.name
            case .uncategorized:             "카테고리 없음".localized()
            case .favorite:                  "즐겨찾기한 메모".localized()
            case .all:                       "전체 메모 목록".localized()
            case .trash:                     "휴지통".localized()
            }
        }
        
        var isCategory: Bool {
            switch self {
            case .category: true
            default: false
            }
        }
    }
    
    private let memoVCType: MemoVCType
    private let memoEntityManager = MemoEntityManager.shared
    private let categoryEntityManager = CategoryEntityManager.shared
    
    // memoVCType이 .category인 경우만 값이 존재
    var selectedCategory: Category?
    private var userDefaultCriterion: String? { return UserDefaults.standard.string(forKey: UserDefaultsKeys.orderCriterion.rawValue) }
    
    private lazy var rootView = self.view as! MemoView
    private lazy var categoryNameTextField = rootView.categoryNameTextField
    lazy var smallCardCollectionView = rootView.smallCardCollectionView
    
    private(set) var memoArray: [Memo] = []
    
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
    
    private var cancellables = Set<AnyCancellable>()
    
    init(memoVCType: MemoVCType) {
        
        self.memoVCType = memoVCType
        
        if case let .category(selectedCategory) = memoVCType {
            self.selectedCategory = selectedCategory
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
        setupObservers()
        Task {
            do {
                try await self.updateMemoContents()
            } catch {
                makeAlert(title: "메모 업데이트 실패", message: "메모를 불러오는 데 실패했습니다.", answer: "확인")
            }
        }
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
        if memoVCType == .trash {
            self.navigationItem.rightBarButtonItems = [editButtonItem]
        } else {
            self.navigationItem.rightBarButtonItems = [plusBarButtonItem, editButtonItem]
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
        smallCardCollectionView.dataSource = self
        smallCardCollectionView.delegate = self
        categoryNameTextField.delegate = self
    }
    
    func setupObservers() {
        MemoEntityRepository.shared.memoUpdatedPublisher
            .sink { [weak self] _ in
                guard let self else { return }
                Task {
                    try await self.updateMemoContents()
                }
            }
            .store(in: &cancellables)
        
        if self.memoVCType == MemoVCType.uncategorized {
            NotificationCenter.default.addObserver(self, selector: #selector(memoRecoveredToUncategorized(_:)), name: NSNotification.Name("memoRecoveredToUncategorizedNotification"), object: nil)
            print("복구 notification 추가됨")
        }
        
        Task {
            await ThemeManager.shared.currentThemePublisher
                .sink { [weak self] _ in
                    guard let self else { return }
                    Task {
                        self.rootView.smallCardCollectionView.visibleCells.forEach { cell in
                            // 테마 색에 맞게 그림자를 그리는 작업이 layoutSubviews에서 진행되기 때문...
                            cell.setNeedsLayout()
                        }
                    }
                }
                .store(in: &cancellables)
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
            var selectedMemos: [Memo] = []
            selectedIndexPaths.forEach { [weak self] indexPath in
                guard let self else { return }
                selectedMemos.append(memoArray[indexPath.item])
            }
            Task {
                try await MemoEntityRepository.shared.restore(selectedMemos)
                try await self.updateMemoContents()
            }
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
        let selectedIndexes = selectedIndexPaths.map(\.item)
        let selectedMemos = memoArray.enumerated()
            .filter { selectedIndexes.contains($0.offset) }
            .map(\.element)
        
        Task {
            try await MemoEntityRepository.shared.setFavorite(selectedMemos, to: true)
            self.setEditing(false, animated: true)
        }
    }
    
    func unlikeFavoriteSelectedMemos() {
        guard smallCardCollectionView.isEditing else { return }
        guard let selectedIndexPaths = smallCardCollectionView.indexPathsForSelectedItems else {
            return
        }
        let selectedIndexes = selectedIndexPaths.map(\.item)
        let selectedMemos: [Memo] = memoArray.enumerated()
            .filter { selectedIndexes.contains($0.offset) }
            .map(\.element)
        
        Task {
            try await MemoEntityRepository.shared.setFavorite(selectedMemos, to: false)
            
            guard self.memoVCType == .favorite else { return }
            try await self.updateMemoContents()
            self.setEditing(false, animated: true)
        }
        
    }
    
}


private extension MemoViewController {
    
    @objc func presentMemoMakingVC() {
        self.view.endEditing(true)
        let memoMakingVC = MemoDetailViewController(type: .making(category: selectedCategory))
        let naviCon = UINavigationController(rootViewController: memoMakingVC)
        self.present(naviCon, animated: true)
    }
    
    @objc func deleteEverySelectedMemo() {
        guard self.smallCardCollectionView.isEditing else { return }
        guard let selectedIndexPaths = self.smallCardCollectionView.indexPathsForSelectedItems else { return }
        
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
            let selectedIndexes = selectedIndexPaths.map(\.item)
            let selectedMemos: [Memo] = self.memoArray.enumerated()
                .filter { selectedIndexes.contains($0.offset) }
                .map(\.element)
            
            Task {
                if self.memoVCType == .trash {
                    try await MemoEntityRepository.shared.deleteMemos(selectedMemos)
                } else {
                    try await MemoEntityRepository.shared.moveToTrash(selectedMemos)
                }
                try await self.updateMemoContents()
            }
            self.setEditing(false, animated: true)
            self.editButtonItem.isEnabled = !self.memoArray.isEmpty
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
    
    //메모가 추가된 후 Notification을 받았을 때 실행할 함수
    @objc func memoCreated(_ notification: Notification) {
        view.endEditing(true)
        Task {
            try await self.updateMemoContents()
        }
    }
    
    @objc func memoRecoveredToUncategorized(_ notification: Notification) {
        print("uncategorized MemoVC에서 메모 복구 Notification 받았다!!")
//        guard let recoveredMemo = notification.userInfo?["recoveredMemos"] as? [MemoEntity] else { fatalError() }
        Task {
            try await self.updateMemoContents()
        }
    }
    
    func presentPopupCardVC(at indexPath: IndexPath, inset: UIEdgeInsets, editingEnabled: Bool = true) {
        let wispConfiguration = WispConfiguration { config in
            config.setAnimation { animation in
                animation.speed = .fast
            }
            config.setLayout { layout in
                layout.presentedAreaInset = inset
                layout.initialCornerRadius = 13
                layout.finalCornerRadius = 25
            }
            config.setGesture { gesture in
                gesture.allowedDirections = [.horizontal, .down]
            }
        }
        
        let selectedMemo = memoArray[indexPath.item]
        let popupCardVC = PopupCardViewController(
            memo: selectedMemo,
            indexPath: .init(item: 0, section: 0),
            editingEnabled: editingEnabled
        )
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
        return self.memoArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch collectionView {
        case self.smallCardCollectionView:
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SmallCardCollectionViewCell.cellID, for: indexPath) as? SmallCardCollectionViewCell else {
                fatalError("Cell couldn't dequeued")
            }
            cell.configure(with: self.memoArray[indexPath.item])
            cell.onLongPressSelected = { [weak self] in
                self?.presentPopupCardVC(
                    at: indexPath,
                    inset: .init(top: 100, left: 10, bottom: 100, right: 10),
                    editingEnabled: false
                )
            }
            if !smallCardCollectionView.isEditing {
                cell.opaqueView.alpha = 0.0
            }
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
    
    func updateMemoContents() async throws {
        memoArray = try await fetchMemos()
        smallCardCollectionView.reloadData()
    }
    
    func fetchMemos() async throws -> [Memo] {
        switch memoVCType {
        case .category, .uncategorized:
            return try await MemoEntityRepository.shared.getAllMemos(inCategory: selectedCategory)
        case .favorite:
            return try await MemoEntityRepository.shared.getFavoriteMemos()
        case .all:
            return try await MemoEntityRepository.shared.getAllMemos()
        case .trash:
            return try await MemoEntityRepository.shared.getAllMemosInTrash()
        }
    }
    
}


// MARK: - UITextFieldDelegate
extension MemoViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        editButtonItem.isEnabled = false
        plusBarButtonItem.isEnabled = false
        navigationItem.setHidesBackButton(true, animated: true)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard case .category(let selectedCategory) = memoVCType else { return }
        let oldCategoryName = selectedCategory.name
        guard let newCategoryName = textField.text else { return }
        let trimmedNewCategoryName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard oldCategoryName != trimmedNewCategoryName else {
            textField.text = oldCategoryName
            editButtonItem.isEnabled = true
            plusBarButtonItem.isEnabled = true
            navigationItem.setHidesBackButton(false, animated: true)
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            return
        }
        
        Task {
            do {
                try await CategoryEntityRepository.shared.changeCategoryName(selectedCategory, newName: trimmedNewCategoryName)
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
            editButtonItem.isEnabled = true
            plusBarButtonItem.isEnabled = true
            navigationItem.setHidesBackButton(false, animated: true)
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
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
