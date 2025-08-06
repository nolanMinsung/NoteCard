//
//  CategorySelectionViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/12/17.
//

import UIKit

class CategorySelectionViewController: UIViewController {
    
    enum SelectionType {
        case toAppend
        case toRemove
    }
    
    let selectionType: SelectionType
    
    let categoryListCollectionView: UICollectionView = {
        let flowLayout = LeftAlignedFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.estimatedItemSize = CGSize(width: 50, height: 30)
        flowLayout.minimumInteritemSpacing = 5
        
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.register(MemoDetailViewCategoryListCell.self, forCellWithReuseIdentifier: MemoDetailViewCategoryListCell.cellID)
        collectionView.clipsToBounds = true
        collectionView.isScrollEnabled = true
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.allowsMultipleSelection = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    
    var categoryEntitiesArray: [CategoryEntity] {
        return CategoryEntityManager.shared.getCategoryEntities(inOrderOf: .modificationDate, isAscending: false)
    }
    var selectedCategorySet: Set<CategoryEntity> = []
    
    
    init(selectionType: SelectionType) {
        self.selectionType = selectionType
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.isModalInPresentation = true
        setupUI()
        setupNaviBar()
        setupConstraints()
        setupSheetPresentationController()
        setupDelegates()
    }
    
    
    private func setupUI() {
        self.view.backgroundColor = .secondarySystemBackground
        self.view.addSubview(categoryListCollectionView)
    }
    
    private func setupNaviBar() {
        self.title = "카테고리 선택하기".localized()
        self.navigationController?.navigationBar.tintColor = .currentTheme
        let cancelBarButtonItem = UIBarButtonItem(title: "취소".localized(), style: UIBarButtonItem.Style.done, target: self, action: #selector(cancelCategorySelection))
        let appendBarButtonItem = UIBarButtonItem(title: "추가".localized(), style: UIBarButtonItem.Style.done, target: self, action: #selector(appendCategories))
        let removeBarButtonItem = UIBarButtonItem(title: "해제".localized(), style: UIBarButtonItem.Style.done, target: self, action: #selector(removeCategories))
        
        self.navigationItem.leftBarButtonItem = cancelBarButtonItem
        
        appendBarButtonItem.isEnabled = false
        removeBarButtonItem.isEnabled = false
        
        switch self.selectionType {
        case .toAppend:
            self.navigationItem.rightBarButtonItem = appendBarButtonItem
        case .toRemove:
            self.navigationItem.rightBarButtonItem = removeBarButtonItem
        }
        
    }
    
    @objc private func cancelCategorySelection() {
        self.dismiss(animated: true)
    }
    
    @objc private func appendCategories() {
        guard let tabBarCon = self.presentingViewController as? UITabBarController else { fatalError() }
        guard let naviCon = tabBarCon.selectedViewController as? UINavigationController else { fatalError() }
        guard let memoVC = naviCon.topViewController as? MemoViewController else { fatalError() }
        guard let selectedIndexPaths = memoVC.smallCardCollectionView.indexPathsForSelectedItems else { fatalError() }
        
        selectedIndexPaths.forEach { [weak self] indexPath in
            guard let self else { fatalError() }
            let selectedMemoEntity = memoVC.memoEntitiesArray[indexPath.item]
            selectedMemoEntity.addToCategories(self.selectedCategorySet as NSSet)
            MemoEntityManager.shared.restoreMemo(selectedMemoEntity)
        }
        
        if memoVC.memoVCType == .trash || memoVC.memoVCType == .uncategorized {
            memoVC.updateDataSource()
            memoVC.smallCardCollectionView.deleteItems(at: selectedIndexPaths)
        }
        
        memoVC.isEditing = false
        self.dismiss(animated: true)
        
        guard let presentingTabBarCon = self.presentingViewController as? UITabBarController else { fatalError() }
        presentingTabBarCon.setEditing(false, animated: true)
    }
    
    
    @objc private func removeCategories() {
        guard let tabBarCon = self.presentingViewController as? UITabBarController else { fatalError() }
        guard let naviCon = tabBarCon.selectedViewController as? UINavigationController else { fatalError() }
        guard let memoVC = naviCon.topViewController as? MemoViewController else { fatalError() }
        guard let selectedIndexPaths = memoVC.smallCardCollectionView.indexPathsForSelectedItems else { fatalError() }
        
        selectedIndexPaths.forEach { [weak self] indexPath in
            guard let self else { return }
//            guard let selectedCell = memoVC.smallCardCollectionView.cellForItem(at: indexPath) as? SmallCardCollectionViewCell else { return }
//            guard let memoToBeRemoved = selectedCell.memoEntity else { return }
            let selectedMemoEntity = memoVC.memoEntitiesArray[indexPath.item]
            selectedMemoEntity.removeFromCategories(self.selectedCategorySet as NSSet)
        }
        
        if memoVC.memoVCType == .category,
           let selectedCategoryEntity = memoVC.selectedCategoryEntity,
           self.selectedCategorySet.contains(selectedCategoryEntity) {
            let selectedIndexes = selectedIndexPaths.map({ $0.item })
            memoVC.updateDataSource()
            memoVC.smallCardCollectionView.deleteItems(at: selectedIndexPaths)
        }
        
        memoVC.isEditing = false
        self.dismiss(animated: true)
        
        guard let presentingTabBarCon = self.presentingViewController as? UITabBarController else { fatalError() }
        presentingTabBarCon.setEditing(false, animated: true)
    }
    
    private func setupConstraints() {
        self.categoryListCollectionView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        self.categoryListCollectionView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 10).isActive = true
        self.categoryListCollectionView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
        self.categoryListCollectionView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
    }
    
    private func setupSheetPresentationController() {
        
        self.sheetPresentationController?.detents = [UISheetPresentationController.Detent.medium()]
        self.sheetPresentationController?.prefersScrollingExpandsWhenScrolledToEdge = false
        self.sheetPresentationController?.prefersGrabberVisible = false
    }
    
    private func setupDelegates() {
        self.categoryListCollectionView.dataSource = self
        self.categoryListCollectionView.delegate = self
    }
    
}





extension CategorySelectionViewController: UICollectionViewDataSource {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        let categoryEntityArray = CategoryEntityManager.shared.getCategoryEntities(inOrderOf: CategoryProperties.modificationDate, isAscending: false)
        return self.categoryEntitiesArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard collectionView == self.categoryListCollectionView else {
            fatalError("unknown collection view has set dataSource delegate to self")
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MemoDetailViewCategoryListCell.cellID, for: indexPath) as! MemoDetailViewCategoryListCell
        let categoryEntity = self.categoryEntitiesArray[indexPath.row]
        
        cell.configureCell(with: categoryEntity)
        
        if self.selectedCategorySet.contains(categoryEntity) {
            self.categoryListCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: UICollectionView.ScrollPosition())
        } else {
            self.categoryListCollectionView.deselectItem(at: indexPath, animated: true)
        }
        
        return cell
    }
    
}



extension CategorySelectionViewController: UICollectionViewDelegate {
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView == self.categoryListCollectionView else { fatalError() }
        let selectedCategory = self.categoryEntitiesArray[indexPath.row]
        switch self.selectedCategorySet.insert(selectedCategory).inserted {
        case true:
            print("selectedCategory has inserted into temporary category set.")
        case false:
            fatalError("inserting selectedCategory into temporary category set failed.")
        }
        if self.categoryListCollectionView.indexPathsForSelectedItems?.count == 0 {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
        
//        self.title = "\(self.categoryListCollectionView.indexPathsForSelectedItems?.count ?? 0)개의 카테고리 선택됨"
        self.title = String(format: "%d개의 카테고리 선택됨".localized(), self.categoryListCollectionView.indexPathsForSelectedItems?.count ?? 0)
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard collectionView == self.categoryListCollectionView else { fatalError() }
        let categoryEntityToRemove = self.categoryEntitiesArray[indexPath.row]
        self.selectedCategorySet.remove(categoryEntityToRemove)
        if self.categoryListCollectionView.indexPathsForSelectedItems?.count == 0 {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
        
        guard let numberOfSelectedCategories = self.categoryListCollectionView.indexPathsForSelectedItems?.count else { fatalError() }
        self.title = numberOfSelectedCategories == 0 ? "카테고리 선택하기".localized() : String(format: "%d개의 카테고리 선택됨".localized(), numberOfSelectedCategories)
    }
    
    
}
