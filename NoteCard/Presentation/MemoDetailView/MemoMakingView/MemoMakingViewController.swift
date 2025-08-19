//
//  MemoMakingViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit
import PhotosUI
//import Photos

class MemoMakingViewController: UIViewController {
    
    enum Section: CaseIterable {
        case main
    }
    
    private let memoEntityManager = MemoEntityManager.shared
    private let imageEntityManager = ImageEntityManager.shared
    
    private var temporaryMemoEntity: MemoEntity!
    private var thumbnailArray: [UIImage] = []
    private var imageDiffableDataSource: UICollectionViewDiffableDataSource<Section, ImageEntity>!
    
    private let selectedCategoryEntity: CategoryEntity?
    
    private let rootView = MemoDetailView()
    
    private lazy var selectedImageCollectionView = rootView.imageCollectionView
    private lazy var categoryListCollectionView = rootView.categoryListCollectionView
    private lazy var titleTextField = rootView.titleTextField
    private lazy var memoTextView = rootView.memoTextView
    
    var categoryEntityArray: [CategoryEntity] {
        return CategoryEntityManager.shared.getCategoryEntities(inOrderOf: CategoryProperties.modificationDate, isAscending: false)
    }
    
    let cancelBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem()
        item.title = "취소".localized()
        return item
    }()
    
    let completeBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem()
        item.title = "완료".localized()
        return item
    }()
    
    let photoBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem()
        item.image = UIImage(systemName: "photo")
        item.tintColor = UIColor.currentTheme
        return item
    }()
    
    var labelBarButtonItem: UIBarButtonItem {
        let label = UILabel()
        label.textColor = .label
        label.numberOfLines = 1
//        label.text = "\(self.categoryListCollectionView.indexPathsForSelectedItems?.count ?? 999)개의 카테고리 선택됨"
        label.text = String(format: "%d개의 카테고리 선택됨".localized(), self.categoryListCollectionView.indexPathsForSelectedItems?.count ?? 999)
        let item = UIBarButtonItem(customView: label)
        return item
    }
    
    init(category categoryEntity: CategoryEntity? = nil) {
        print("MemoMakingViewController 생성됨.")
        self.selectedCategoryEntity = categoryEntity
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = rootView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.isModalInPresentation = true
        setupDiffableDataSource()
        makeTemporaryMemoEntity()
        setupButtonsAction()
        setupNaviBar()
        setupToolbar()
        setupDelegates()
        setupObserver()
    }
    
    deinit {
        print("MemoMakingViewController 해제됨.")
    }
    
    func setupDiffableDataSource() {
        self.imageDiffableDataSource = UICollectionViewDiffableDataSource<Section, ImageEntity>(collectionView: self.selectedImageCollectionView, cellProvider: { collectionView, indexPath, imageEntity in
            
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MemoDetailViewSelectedImageCell.cellID,
                for: indexPath
            ) as? MemoDetailViewSelectedImageCell else {
                fatalError("cell dequeuing failed.")
            }
            
            cell.configureCell(with: imageEntity)
            return cell
        })
    }
    
    /// - Parameters:
    ///   - animatingDifferences: snapshot을 apply하며 애니메이션 할 것인지의 여부
    ///   - usingReloadData: collectionViewCell을 drag and drop 시에 animatingDifferences를 false로 해도 이상한 애니메이션이 생겨벼린다. 이때, apply 직후에 reloadData()를 호출하면 애니메이션이 동작하지 않기에, 이를 위해 바로 직후에 reloadData() 를 호출할 지 여부를 매개변수로 만들었음.
    ///   - completion: completion. 시스템이 자동으로 메인 큐에서 이 코드 블럭을 호출해준다.
    private func applySnapshot(animatingDifferences: Bool, usingReloadData: Bool, completion: (() -> Void)? = nil) {
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, ImageEntity>()
        snapshot.appendSections([.main])
        snapshot.appendItems(
            ImageEntityManager.shared.getImageEntities(
                from: self.temporaryMemoEntity,
                inOrderOf: ImageOrderIndexKind.temporaryOrderIndex,
                isTemporaryDeleted: false),
            toSection: .main
        )
        
        switch usingReloadData {
        case true:
            self.imageDiffableDataSource.applySnapshotUsingReloadData(snapshot, completion: completion)
        case false:
            self.imageDiffableDataSource.apply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
        }
        
    }
    
    private func makeTemporaryMemoEntity() {
        let categorySet: Set<CategoryEntity> = (self.selectedCategoryEntity != nil
                                                ? [self.selectedCategoryEntity!]
                                                : Set<CategoryEntity>())
        
        self.temporaryMemoEntity = self.memoEntityManager.createMemoEntity(
            memoTitleText: "",
            memoText: "",
            categorySet: categorySet
        )
    }
    
    private func setupButtonsAction() {
        self.cancelBarButtonItem.target = self
        self.cancelBarButtonItem.action = #selector(cancelButtonTapped)
        
        self.completeBarButtonItem.target = self
        self.completeBarButtonItem.action = #selector(completeMaking)
        
        self.photoBarButtonItem.target = self
        self.photoBarButtonItem.action = #selector(presentphPickerVC)
    }
    
    @objc private func cancelButtonTapped() {
        guard let temporaryMemoEntity else { fatalError() }
        view.endEditing(true)
        let alertCon = UIAlertController(title: "메모 작성 취소".localized(), message: "메모 작성을 취소하시겠습니까?".localized(), preferredStyle: UIAlertController.Style.alert)
        let cancelCancelingAction = UIAlertAction(title: "계속 작성".localized(), style: UIAlertAction.Style.default)
        let cancelingAction = UIAlertAction(title: "메모 작성 취소".localized(), style: UIAlertAction.Style.destructive) { action in
            self.memoEntityManager.deleteMemoEntity(memoEntity: temporaryMemoEntity)
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
            appDelegate.memoMakingVC = nil
            self.dismiss(animated: true)
        }
        alertCon.addAction(cancelCancelingAction)
        alertCon.addAction(cancelingAction)
        alertCon.view.tintColor = .currentTheme
        
        self.present(alertCon, animated: true)
    }
    
    @objc func completeMaking() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        guard let titleText = self.titleTextField.text else { return }
        guard let memoText = self.memoTextView.text else { return }
        
        self.temporaryMemoEntity.memoTitle = titleText
        
        if self.memoTextView.textColor == .systemGray4 {
            self.temporaryMemoEntity.memoText = ""
        } else {
            self.temporaryMemoEntity.memoText = memoText
        }
        
        let temporaryAppendedImageEntities = self.imageEntityManager.getImageEntities(from: self.temporaryMemoEntity, inOrderOf: ImageOrderIndexKind.temporaryOrderIndex)
        temporaryAppendedImageEntities.forEach { imageEntity in
            imageEntity.isTemporaryDeleted = false
            imageEntity.isTemporaryAppended = false
            imageEntity.orderIndex = imageEntity.temporaryOrderIndex
        }
        
        guard let categoryEntityList = self.temporaryMemoEntity.categories?.sortedArray(using: []) as? [CategoryEntity] else {
            fatalError("temporaryMemoEnity's categories's sortedArray method return nil")
        }
        
        categoryEntityList.forEach { category in
            category.modificationDate = Date()
            print("modificationDate of <\(category.name)> changed to \(Date())")
        }
        
        CoreDataStack.shared.saveContext()
        print("메모의 코어데이터 생성")
        appDelegate.memoMakingVC = nil
        
        guard let temporaryMemoEntity else { fatalError() }
        NotificationCenter.default.post(name: NSNotification.Name("createdMemoNotification"), object: nil, userInfo: ["memo": temporaryMemoEntity])
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
        appDelegate.memoMakingVC = nil
        self.dismiss(animated: true)
    }
    
    
    private func alert(title: String?, message: String?, preferredStyle: UIAlertController.Style) {
        let alertCon = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        let okAction = UIAlertAction(title: "확인".localized(), style: UIAlertAction.Style.cancel)
        alertCon.addAction(okAction)
        self.present(alertCon, animated: true)
    }
    
    @objc private func presentphPickerVC() {
        let selectedImageEntitiesArray = ImageEntityManager.shared.getImageEntities(
            from: self.temporaryMemoEntity,
            inOrderOf: ImageOrderIndexKind.temporaryOrderIndex,
            isTemporaryDeleted: false)
        
        let phPickerConfiguration: PHPickerConfiguration = {
            var config = PHPickerConfiguration()
            config.filter = PHPickerFilter.images
            config.selection = .ordered
            config.selectionLimit = 10 - selectedImageEntitiesArray.count
            return config
        }()
        
        if phPickerConfiguration.selectionLimit != 0 {
            let phPickerVC = PHPickerViewController(configuration: phPickerConfiguration)
            phPickerVC.view.tintColor = .currentTheme
            phPickerVC.delegate = self
            present(phPickerVC, animated: true)
        } else {
            let alertCon = UIAlertController(title: "이미지 한도 초과", message: "메모당 이미지 저장은 최대 10개까지 가능합니다.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "확인", style: UIAlertAction.Style.cancel)
            alertCon.addAction(okAction)
            self.present(alertCon, animated: true)
        }
        
    }
    
    private func setupNaviBar() {
        self.title = "메모 추가하기".localized()
        
        self.navigationController?.navigationBar.tintColor = UIColor.currentTheme
        self.navigationController?.isToolbarHidden = false
        self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem
        self.navigationItem.rightBarButtonItem = self.completeBarButtonItem
    }
    
    private func setupToolbar() {
        let flexibleSpaceItem = UIBarButtonItem(systemItem: .flexibleSpace)
        self.toolbarItems = [
            self.photoBarButtonItem,
            flexibleSpaceItem,
            self.labelBarButtonItem,
            flexibleSpaceItem
        ]
    }
    
    private func setupDelegates() {
        //self.selectedImageCollectionView.dataSource = self
        self.selectedImageCollectionView.delegate = self
        self.selectedImageCollectionView.dragDelegate = self
        self.selectedImageCollectionView.dropDelegate = self
        
        self.categoryListCollectionView.dataSource = self
        self.categoryListCollectionView.delegate = self
    }
    
    
    private func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(selectedImageDeleted(_:)), name: NSNotification.Name("selectedImageDeletedNotification"), object: nil)
    }
    
    
    @objc func selectedImageDeleted(_ notification: Notification?) {
        guard let imageEntity = notification?.userInfo?["imageEntity"] as? ImageEntity else { return }
        self.imageEntityManager.deleteImageEntity(imageEntity: imageEntity)
        
        let imageEntityArray = ImageEntityManager.shared.getImageEntities(from: self.temporaryMemoEntity, inOrderOf: ImageOrderIndexKind.temporaryOrderIndex, isTemporaryDeleted: false)
        
        var index: Int64 = 0
        imageEntityArray.forEach { imageEntity in
            imageEntity.temporaryOrderIndex = index
            index += 1
        }
        
        self.applySnapshot(animatingDifferences: true, usingReloadData: false) { [weak self] in
            guard let self else { fatalError() }
            
            let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
            animator.addAnimations { [weak self] in
                guard let self else { fatalError() }
                
                self.rootView.hideImageCollectionView()
                view.layoutIfNeeded()
            }
            
            if self.selectedImageCollectionView.numberOfItems(inSection: 0) == 0 {
                animator.startAnimation()
            }
        }
    }
    
    private func changeTemporaryOrderIndex(in collectionView: UICollectionView, from fromIndex: Int, to destinationIndex: Int, animatingDifferences: Bool) {
        
        var imageEntityArray = ImageEntityManager.shared.getImageEntities(from: self.temporaryMemoEntity, inOrderOf: ImageOrderIndexKind.temporaryOrderIndex, isTemporaryDeleted: false)
        
        let removedImageEntity = imageEntityArray.remove(at: fromIndex)
        imageEntityArray.insert(removedImageEntity, at: destinationIndex)
        
        var i: Int64 = 0
        imageEntityArray.forEach { imageEntity in
            imageEntity.temporaryOrderIndex = i
            i += 1
        }
        
        self.applySnapshot(animatingDifferences: animatingDifferences, usingReloadData: true)
    }
    
}


// MARK: - UICollectionViewDataSource
extension MemoMakingViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard collectionView == self.categoryListCollectionView else { fatalError() }
        let categoryEntityArray = CategoryEntityManager.shared.getCategoryEntities(
            inOrderOf: CategoryProperties.modificationDate,
            isAscending: false
        )
        return categoryEntityArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard collectionView == self.categoryListCollectionView else { fatalError() }
        let cell = self.categoryListCollectionView.dequeueReusableCell(withReuseIdentifier: MemoDetailViewCategoryListCell.cellID, for: indexPath) as! MemoDetailViewCategoryListCell
        let categoryEntity = self.categoryEntityArray[indexPath.row]
        
        cell.configureCell(with: categoryEntity)
        
        if let temporarySelectedCategories = self.temporaryMemoEntity?.categories {
            if temporarySelectedCategories.contains(categoryEntity) {
                self.categoryListCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .init())
                self.setupToolbar()
            } else {
                self.categoryListCollectionView.deselectItem(at: indexPath, animated: true)
            }
        }
        
        return cell
    }
}


// MARK: - UICollectionViewDelegate
extension MemoMakingViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        //선택된 이미지를 보여주는 컬렉션뷰일 경우
        if collectionView == self.selectedImageCollectionView {
            let temporaryImageEntitiesArray = ImageEntityManager.shared.getImageEntities(
                from: self.temporaryMemoEntity,
                inOrderOf: ImageOrderIndexKind.temporaryOrderIndex,
                isTemporaryDeleted: false
            )
            
            let temporaryImagesArray = temporaryImageEntitiesArray.map({
                guard let image = ImageEntityManager.shared.getImage(imageEntity: $0) else { fatalError() }
                return image
            })
            
            let cardImageShowingVC = CardImageShowingViewController(indexPath: indexPath, imageEntitiesArray: temporaryImageEntitiesArray)
            cardImageShowingVC.transitioningDelegate = self
            cardImageShowingVC.modalPresentationStyle = .custom
            self.present(cardImageShowingVC, animated: true)
            
        //카테고리를 선택하는 컬렉션뷰일 경우
        } else if collectionView == self.categoryListCollectionView {
            let selectedCategory = self.categoryEntityArray[indexPath.row]
            self.temporaryMemoEntity?.addToCategories(selectedCategory)
            self.setupToolbar()
            
        } else {
            fatalError()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        if collectionView == self.categoryListCollectionView {
            let deselectedCategory = self.categoryEntityArray[indexPath.row]
            self.temporaryMemoEntity?.removeFromCategories(deselectedCategory)
            self.setupToolbar()
        }
    }
    
}


// MARK: - UICollectionViewDragDelegate
extension MemoMakingViewController: UICollectionViewDragDelegate {
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        print(#function)
        return [UIDragItem(itemProvider: NSItemProvider())]
    }
    
    
    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        
        let previewParameters = UIDragPreviewParameters()
        let bezierPath = UIBezierPath(
            roundedRect: CGRect(
                x: 0,
                y: 0,
                width: CGSizeConstant.compositionalCardThumbnailSize.width,
                height: CGSizeConstant.compositionalCardThumbnailSize.height),
            cornerRadius: 10)
        
        previewParameters.visiblePath = bezierPath
        return previewParameters
    }
    
    //드래그가 시작하면 불리는 메서드이므로, 삭제 버튼을 없애기 좋은 위치임.
    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        print(#function)
    }
    
    //Drag가 끝나면 불리는 메서드. Drop이 있을 경우, Drop 후에 마지막으로 불리는 듯
    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        print(#function)
    }
}


// MARK: - UICollectionViewDropDelegate
extension MemoMakingViewController: UICollectionViewDropDelegate {
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        print(#function)
        
        if destinationIndexPath != nil {
            return UICollectionViewDropProposal.init(operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            return UICollectionViewDropProposal.init(operation: .forbidden)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        print(#function)
        
        guard let item = coordinator.items.first,
              let sourceIndexPath = item.sourceIndexPath else { return }
        
        var destination: IndexPath
        if let destinationIndexPath = coordinator.destinationIndexPath {
            destination = destinationIndexPath
        } else {
            destination = IndexPath(row: self.thumbnailArray.count - 1, section: 0)
        }
        
        if coordinator.proposal.operation == UIDropOperation.move {
            
            self.changeTemporaryOrderIndex(in: collectionView, from: sourceIndexPath.row, to: destination.row, animatingDifferences: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
        
    }
    
}


// MARK: - PHPickerViewControllerDelegate
extension MemoMakingViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        picker.dismiss(animated: true)
        let temporaryImageEntities = self.temporaryMemoEntity.images //{
        var index: Int = temporaryImageEntities.count
        var countDown: Int = results.count
        guard results.count != 0 else { return }
        self.completeBarButtonItem.isEnabled = false
        self.photoBarButtonItem.isEnabled = false
        self.rootView.showImageCollectionView(targetHeight: CGSizeConstant.detailViewThumbnailSize.height)
        self.selectedImageCollectionView.isScrollEnabled = false
        self.selectedImageCollectionView.alpha = 0.3
        self.rootView.startImageCollectionViewLoading()
        
        results.forEach { result in
            let itemProvider = result.itemProvider
            
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                //Asynchronous
                itemProvider.loadObject(ofClass: UIImage.self) { [weak self, index] image, error in
                    guard let self else { return }
                    guard let image = image as? UIImage else {
                        fatalError("image couldn't loaded")
                    }
                    print(index)
                    let _ = self.imageEntityManager.createImageEntity(image: image, orderIndex: index, memoEntity: self.temporaryMemoEntity, isTemporaryAppended: true)
                    
                    countDown -= 1
                    if countDown == 0 {
                        DispatchQueue.main.async { [weak self] in
                            guard let self else { fatalError() }
                            
                            self.applySnapshot(animatingDifferences: true, usingReloadData: true) { [weak self] in
                                guard let self else { fatalError() }
                                self.completeBarButtonItem.isEnabled = true
                                self.photoBarButtonItem.isEnabled = true
                                self.rootView.stopImageCollectionViewLoading()
                                self.selectedImageCollectionView.isScrollEnabled = true
                                self.selectedImageCollectionView.alpha = 1
                                
                                if self.selectedImageCollectionView.contentSize.width + self.selectedImageCollectionView.contentInset.left + self.selectedImageCollectionView.contentInset.right > self.selectedImageCollectionView.bounds.width {
                                    
                                    self.selectedImageCollectionView.setContentOffset(
                                        CGPoint(x: self.selectedImageCollectionView.contentSize.width - self.selectedImageCollectionView.bounds.width + self.selectedImageCollectionView.contentInset.right, y: 0),
                                        animated: true
                                    )
                                }
                            }
                        }
                    }
                }
                
                //phPickerViewController로 이미지를 불러오지 못하는 경우 (wobP 포맷일 때)
            } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.webP.identifier) {
                //Asynchronous
                itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.webP.identifier) { [weak self, index] data, error in
                    guard let self else { fatalError() }
                    guard let data else { return }
                    guard let webpToUIImage = UIImage(data: data) else { return }
                    
                    print(index)
                    let _ = self.imageEntityManager.createImageEntity(image: webpToUIImage, orderIndex: index, memoEntity: self.temporaryMemoEntity, isTemporaryAppended: true)
                    
                    countDown -= 1
                    
                    //가장 늦게 로드된 사진이 작업을 끝마치면 다음 코드 실행
                    if countDown == 0 {
                        DispatchQueue.main.async { [weak self] in
                            guard let self else { fatalError() }
                            
                            self.applySnapshot(animatingDifferences: true, usingReloadData: true) { [weak self] in
                                guard let self else { fatalError() }
                                self.completeBarButtonItem.isEnabled = true
                                self.photoBarButtonItem.isEnabled = true
                                self.rootView.stopImageCollectionViewLoading()
                                self.selectedImageCollectionView.isScrollEnabled = true
                                self.selectedImageCollectionView.alpha = 1
                                
                                if self.selectedImageCollectionView.contentSize.width + self.selectedImageCollectionView.contentInset.left + self.selectedImageCollectionView.contentInset.right > self.selectedImageCollectionView.bounds.width {
                                    
                                    self.selectedImageCollectionView.setContentOffset(
                                        CGPoint(x: self.selectedImageCollectionView.contentSize.width - self.selectedImageCollectionView.bounds.width + self.selectedImageCollectionView.contentInset.right, y: 0),
                                        animated: true
                                    )
                                }
                            }
                        }
                    }
                }
            } else {
                // 애플 공식 답변은 iCloud에서 다운받기 위해 별다른 조치 안해도 된다고 했는데, 왜 여기로 넘어옴?
                // https://developer.apple.com/forums/thread/679884
                fatalError("아이클라우드에서 받아와야하는데 안받아오고 바로 여기로 넘어옴...??")
            }
            index += 1
        }
        //        }
    }
}


// MARK: - UIViewControllerTransitioningDelegate
extension MemoMakingViewController: UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CardImageShowingPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return CardImageShowingAnimatedTransitioning(animationType: .present)
    }
    
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return CardImageShowingAnimatedTransitioning(animationType: .dismiss)
    }
    
}
