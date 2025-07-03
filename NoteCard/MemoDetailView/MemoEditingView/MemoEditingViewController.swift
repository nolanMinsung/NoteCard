//
//  MemoEditingViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit
import Photos // PHAsset을 위한 것
import PhotosUI //PHPicekrViewController를 위한 것

class MemoEditingViewController: UIViewController {
    
    enum SelectedImageCollectionViewSection: CaseIterable {
        case main
    }
    
    let categoryEntityManager = CategoryEntityManager.shared
    let memoEntityManager = MemoEntityManager.shared
    let imageEntityManager = ImageEntityManager.shared
    let phImageManager = PHImageManager.default()
    let fileManager = FileManager.default
    
    var temporaryCategorySet: Set<CategoryEntity>
    //var addedAssetsArray: [PHAsset] = []
    var temporaryAddedImageEntities: [ImageEntity] = []
    var selectedMemoEntity: MemoEntity
    var imageDiffableDataSource: UICollectionViewDiffableDataSource<SelectedImageCollectionViewSection, ImageEntity>!
//    var labelBarButtonItem: UIBarButtonItem {
//        self.memoDetailView.labelBarButtonItem
//    }
    
    var thumbnailArray: [UIImage] {
        var array: [UIImage] = []
        let imageEntitiesArray = self.imageEntityManager.getImageEntities(
            from: self.selectedMemoEntity,
            inOrderOf: ImageOrderIndexKind.temporaryOrderIndex, 
            isTemporaryDeleted: false
        )
        imageEntitiesArray.forEach { imageEntity in
            if let thumbnail = self.imageEntityManager.getThumbnailImage(imageEntity: imageEntity) {
                array.append(thumbnail)
            }
        }
        return array
    }
    
    lazy var memoDetailView = self.view as! MemoDetailView
    lazy var selectedImageCollectionView = self.memoDetailView.selectedImageCollectionView
    lazy var activityIndicatorView = self.memoDetailView.activityIndicatorView
    lazy var categoryListCollectionView = self.memoDetailView.categoryListCollectionView
    lazy var titleTextField = self.memoDetailView.titleTextField
    lazy var memoTextView = self.memoDetailView.memoTextView
//    lazy var flexibleSpaceBarButtonItem = self.memoDetailView.flexibleSpaceBarButtonItem
//    lazy var photoBarButtonItem = self.memoDetailView.photoBarButtonItem
    lazy var selectedImageCollectionViewTopConstraint = self.memoDetailView.selectedImageCollectionViewTopConstraint
    lazy var selectedImageCollectionViewHeightConstraint = self.memoDetailView.selectedImageCollectionViewHeightConstraint
    lazy var memoTextViewBottomConstraint = self.memoDetailView.memoTextViewBottomConstraint
//    lazy var memoTextViewHeightConstraint = self.memoDetailView.memoTextViewHeightConstraint
    
    
    var categoryEntityArray: [CategoryEntity] {
        return self.categoryEntityManager.getCategoryEntities(inOrderOf: CategoryProperties.modificationDate, isAscending: false)
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
        item.tintColor = UIColor.currentTheme()
        return item
    }()
    
    let flexibleSpaceBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(systemItem: UIBarButtonItem.SystemItem.flexibleSpace)
        return item
    }()
    
    var labelBarButtonItem: UIBarButtonItem {
        let label = UILabel()
        label.textColor = .label
        label.numberOfLines = 1
        label.text = String(format: "%d개의 카테고리 선택됨".localized(), self.temporaryCategorySet.count)
        let item = UIBarButtonItem(customView: label)
        return item
    }
    
    
    
    
    init(memo memoEntity: MemoEntity) {
        self.selectedMemoEntity = memoEntity
        self.temporaryCategorySet = memoEntity.categories as! Set<CategoryEntity>
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func loadView() {
        self.view = MemoDetailView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.isModalInPresentation = true
        setupDiffableDataSource()
        applySnapshot(animatingDifferences: true, usingReloadData: false)
        setupButtonsAction()
        setupNaviBar()
        setupToolbar()
        setupDelegates()
        loadTextsAndImages()
        setupObserver()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if thumbnailArray.count == 0 {
            self.selectedImageCollectionViewTopConstraint.constant = 0
            self.selectedImageCollectionViewHeightConstraint.constant = 0
            
        } else {
            self.selectedImageCollectionViewTopConstraint.constant = 17
            self.selectedImageCollectionViewHeightConstraint.constant = CGSizeConstant.compositionalCardThumbnailSize.height
        }
        
        self.applySnapshot(animatingDifferences: true, usingReloadData: false)
        
        
        
    }
    
    
    
    private func setupDiffableDataSource() {
        
        self.imageDiffableDataSource = UICollectionViewDiffableDataSource(collectionView: self.selectedImageCollectionView, cellProvider: { collectionView, indexPath, imageEntity in
            
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MemoDetailViewSelectedImageCell.cellID,
                for: indexPath
            ) as? MemoDetailViewSelectedImageCell else {
                fatalError("Cell couldn't dequeued")
            }
            
            //cell.selectedImageView.image = ImageEntityManager.shared.getThumbnailImage(imageEntity: imageEntity)
            cell.configureCell(with: imageEntity)
            return cell
        })
        
    }
    
    
    
    /// 현재 수정 중인 화면에 기존 이미지와 임시로 추가된 이미지, 임시로 삭제된 이미지를 반영
    /// - Parameters:
    ///   - animatingDifferences: snapshot을 apply하며 애니메이션 할 것인지의 여부
    ///   - usingReloadData: collectionViewCell을 drag and drop 시에 animatingDifferences를 false로 해도 이상한 애니메이션이 생겨벼린다. 이때, apply 직후에 reloadData()를 호출하면 애니메이션이 동작하지 않기에, 이를 위해 바로 직후에 reloadData() 를 호출할 지 여부를 매개변수로 만들었음.
    private func applySnapshot(animatingDifferences: Bool, usingReloadData: Bool, completion: (() -> Void)? = nil) {
        
        //MemoEditingViewController에 보여질 사진은 isTemporaryDeleted == false 이기만 한 사진들을 가져오면 된다.
        var snapshot = NSDiffableDataSourceSnapshot<SelectedImageCollectionViewSection, ImageEntity>()
        snapshot.appendSections([.main])
        snapshot.appendItems(
            ImageEntityManager.shared.getImageEntities(
                from: self.selectedMemoEntity,
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
    
    private func setupButtonsAction() {
        self.cancelBarButtonItem.target = self
        self.cancelBarButtonItem.action = #selector(editingCancel)
        
        self.completeBarButtonItem.target = self
        self.completeBarButtonItem.action = #selector(completeEditing)
        
        self.photoBarButtonItem.target = self
        self.photoBarButtonItem.action = #selector(presentImagePickerVC)
    }
    
    /// blurAnimator을 끝냄
    /// 수정을 취소하며, 변경 사항을 초기화함.
    /// 1. 임시로 추가된 값들을 다시 삭제
    /// 2. 임시로 삭제된 값들을 다시 원상복구
    /// 3-1. 복구된 imageEntity들의 isTemporaryDeleted, isTemporaryAppended 값을 모두 false 로 설정
    /// 3-2. 남아있게 될 imageEntity들의 인덱스 재정리
    @objc private func editingCancel() {
//        let alertCon = UIAlertController(title: "메모 수정 취소", message: "메모 수정을 취소하시겠습니까?", preferredStyle: UIAlertController.Style.alert)
//        let cancelCancelingAction = UIAlertAction(title: "계속 수정", style: UIAlertAction.Style.default)
//        let cancelingAction = UIAlertAction(title: "메모 수정 취소", style: UIAlertAction.Style.destructive) { action in
//            self.view.endEditing(true)
//            
//            //임시로 추가된 값들을 다시 삭제해주기
//            let imageEntitiesTemporaryAppended = self.imageEntityManager.getImageEntities(from: self.selectedMemoEntity, inOrderOf: ImageOrderIndexKind.temporaryOrderIndex, isTemporaryAppended: true)
//            imageEntitiesTemporaryAppended.forEach { imageEntity in
//                self.imageEntityManager.deleteImageEntity(imageEntity: imageEntity)
//            }
//            
//            //1. 임시로 추가되어 다시 삭제해줬던 imageEntity들을 제외한 엔티티들 전부 isTemporaryDeleted = false, isTemporaryAppended = false 로 설정.
//            //  (임시로 삭제된 값들 원상복귀)
//            //2. 남아있어야 할 imageEntity들의 인덱스 재정리.
//            let imageEntityArray = self.imageEntityManager.getImageEntities(from: self.selectedMemoEntity, inOrderOf: ImageOrderIndexKind.orderIndex)
//            imageEntityArray.forEach { imageEntity in
//                imageEntity.isTemporaryDeleted = false
//                imageEntity.isTemporaryAppended = false
//                imageEntity.temporaryOrderIndex = imageEntity.orderIndex
//            }
//            
//            self.dismiss(animated: true)
//        }
//        alertCon.addAction(cancelCancelingAction)
//        alertCon.addAction(cancelingAction)
//        
//        self.present(alertCon, animated: true)
        
        self.memoDetailView.endEditing(true)
        
        //임시로 추가된 값들을 다시 삭제해주기
        let imageEntitiesTemporaryAppended = self.imageEntityManager.getImageEntities(from: self.selectedMemoEntity, inOrderOf: ImageOrderIndexKind.temporaryOrderIndex, isTemporaryAppended: true)
        imageEntitiesTemporaryAppended.forEach { imageEntity in
            self.imageEntityManager.deleteImageEntity(imageEntity: imageEntity)
        }
        
        //1. 임시로 추가되어 다시 삭제해줬던 imageEntity들을 제외한 엔티티들 전부 isTemporaryDeleted = false, isTemporaryAppended = false 로 설정.
        //  (임시로 삭제된 값들 원상복귀)
        //2. 남아있어야 할 imageEntity들의 인덱스 재정리.
        let imageEntityArray = self.imageEntityManager.getImageEntities(from: self.selectedMemoEntity, inOrderOf: ImageOrderIndexKind.orderIndex)
        imageEntityArray.forEach { imageEntity in
            imageEntity.isTemporaryDeleted = false
            imageEntity.isTemporaryAppended = false
            imageEntity.temporaryOrderIndex = imageEntity.orderIndex
        }
        self.memoTextViewBottomConstraint.isActive = false
        self.dismiss(animated: true)
        
    }
    
    
    /// blurAnimator을 끝냄
    /// 수정을 완료하며, 변경 사항을 저장함.
    /// 이미지의 경우, orderIndexPath가 temporaryIndexPath에 맞게 반영됨.
    /// 삭제할 이미지들을 삭제
    /// 추가된 사진들의 isTemporaryAppended 속성을 false로 설정
    @objc func completeEditing() {
        self.memoDetailView.endEditing(true)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        guard let titleText = self.titleTextField.text else { return }
        guard let memoText = self.memoTextView.text else { return }
//        guard !self.temporaryCategorySet.isEmpty else {
//            self.alert(title: "카테고리 선택", message: "최소 1개 이상의 카테고리를 선택하세요", preferredStyle: UIAlertController.Style.alert)
//            return
//        }
        
        selectedMemoEntity.memoTitle = titleText
        selectedMemoEntity.memoText = memoText
        //selectedMemoEntity.categories = EditingVCSelectCategoryCell.selectedCategorySet as NSSet
        selectedMemoEntity.modificationDate = Date()
        appDelegate.saveContext()
        
        //카테고리 변경사항 적용
        self.memoEntityManager.replaceCategories(of: self.selectedMemoEntity, with: self.temporaryCategorySet)
        
        guard let categoryEntityList = self.selectedMemoEntity.categories?.sortedArray(using: []) as? [CategoryEntity] else {
            fatalError("temporaryMemoEnity's categories's sortedArray method return nil")
        }
        
        categoryEntityList.forEach { category in
            category.modificationDate = Date()
        }
        appDelegate.saveContext()
        
        //임시로 삭제한 사진들의 imageEntity들 삭제해주기
        let imageEntitiesToDelete = self.imageEntityManager.getImageEntities(
            from: self.selectedMemoEntity,
            inOrderOf: ImageOrderIndexKind.temporaryOrderIndex,
            isTemporaryDeleted: true
        )
        imageEntitiesToDelete.forEach { imageEntity in
            self.imageEntityManager.deleteImageEntity(imageEntity: imageEntity)
        }
        
        //1. 삭제하고 남은 사진들(삭제하지 않는 기존 사진들 + 새로 추가된 사진들)이 인덱스 재정렬
        //2. 모든 imageEntity들의 isTemporaryDeleted, isTemporaryAppended 값 false 로 설정
        let updatedImageEntities = self.imageEntityManager.getImageEntities(
            from: self.selectedMemoEntity,
            inOrderOf: ImageOrderIndexKind.temporaryOrderIndex,
            isTemporaryDeleted: false
        )
        updatedImageEntities.forEach { imageEntity in
            imageEntity.orderIndex = imageEntity.temporaryOrderIndex
            imageEntity.isTemporaryDeleted = false
            imageEntity.isTemporaryAppended = false
        }
        
        appDelegate.saveContext()
        appDelegate.memoEditingVC = nil
        //여기서부터 보낼 Notification 정보 분기처리
        //1) 수정한 메모가 현재 카테고리에서 사라졌을 때
//        NotificationCenter.default.post(name: NSNotification.Name("editingCompleteAndDisappearMemoNotification"), object: nil)
        
        //2) 수정한 메모가 현재 카테고리에 남아있을 때.
//        NotificationCenter.default.post(name: NSNotification.Name("editingCompleteAndKeepMemoNotification"), object: nil)
        
        //-> 아니면 현재 메모 정보를 Notification 에 같이 담아서 보낸 후, Notification 받는 곳에서 결정하기
        NotificationCenter.default.post(name: NSNotification.Name("editingCompleteNotification"), object: nil, userInfo: ["memo": self.selectedMemoEntity])
        
        self.memoTextViewBottomConstraint.isActive = false
        
        if let popupCardVC = self.presentingViewController as? PopupCardViewController {
            popupCardVC.popupCardView.isEdited = true
            popupCardVC.popupCardView.configureView(with: self.selectedMemoEntity)
        }
        
        self.dismiss(animated: true)
    }
    
    
    
    private func alert(title: String?, message: String?, preferredStyle: UIAlertController.Style) {
        let alertCon = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        let okAction = UIAlertAction(title: "확인".localized(), style: UIAlertAction.Style.cancel)
        alertCon.addAction(okAction)
        self.present(alertCon, animated: true)
    }
    
    
    @objc func presentImagePickerVC() {
        
        let selectedImageEntitiesArray = ImageEntityManager.shared.getImageEntities(
            from: self.selectedMemoEntity,
            inOrderOf: ImageOrderIndexKind.temporaryOrderIndex,
            isTemporaryDeleted: false)
        
        let phPickerConfiguration: PHPickerConfiguration = {
            var config = PHPickerConfiguration()
            config.filter = PHPickerFilter.images
            config.selection = .ordered
            config.selectionLimit = 10 - selectedImageEntitiesArray.count
            return config
        }()
        
        let phPickerVC = PHPickerViewController(configuration: phPickerConfiguration)
        phPickerVC.view.tintColor = .currentTheme()
        phPickerVC.delegate = self
        
        
        if phPickerConfiguration.selectionLimit != 0 {
            self.present(phPickerVC, animated: true)
        } else {
            let alertCon = UIAlertController(title: "이미지 한도 초과".localized(), message: "메모당 이미지 저장은 최대 10개까지 가능합니다.".localized(), preferredStyle: .alert)
            let okAction = UIAlertAction(title: "확인", style: UIAlertAction.Style.cancel)
            alertCon.addAction(okAction)
            self.present(alertCon, animated: true)
        }
    }
    
    private func setupNaviBar() {
        self.title = "편집 모드".localized()
        
        self.navigationController?.navigationBar.tintColor = UIColor.currentTheme()
        self.navigationController?.isToolbarHidden = false
        self.navigationItem.leftBarButtonItem = cancelBarButtonItem
        self.navigationItem.rightBarButtonItem = completeBarButtonItem
    }
    
    private func setupToolbar() {
        self.toolbarItems = [self.photoBarButtonItem, self.flexibleSpaceBarButtonItem, self.labelBarButtonItem, self.flexibleSpaceBarButtonItem]
    }
    
    private func setupDelegates() {
        //self.selectedImageCollectionView.dataSource = self
        self.selectedImageCollectionView.delegate = self
        self.selectedImageCollectionView.dragDelegate = self
        self.selectedImageCollectionView.dropDelegate = self
        
        self.categoryListCollectionView.dataSource = self
        self.categoryListCollectionView.delegate = self
    }
    
    private func loadTextsAndImages() {
        self.titleTextField.text = self.selectedMemoEntity.memoTitle
        //self.memoTextView.text = self.selectedMemoEntity.memoText
        self.memoTextView.setLineSpace(with: self.selectedMemoEntity.memoText, lineSpace: 5, font: UIFont.systemFont(ofSize: 15))
        
    }
    
    
    private func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(selectedImageDeleted(_:)), name: NSNotification.Name("selectedImageDeletedNotification"), object: nil)
    }
    
    
    @objc func selectedImageDeleted(_ notification: Notification?) {
        guard let imageEntity = notification?.userInfo?["imageEntity"] as? ImageEntity else { return }
        imageEntity.isTemporaryDeleted = true
        
        let imageEntityArray = ImageEntityManager.shared.getImageEntities(from: self.selectedMemoEntity, inOrderOf: ImageOrderIndexKind.temporaryOrderIndex, isTemporaryDeleted: false)
        
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
                self.selectedImageCollectionViewTopConstraint.constant = 0
                self.selectedImageCollectionViewHeightConstraint.constant = 0
                self.memoDetailView.layoutIfNeeded()
            }
            
            if self.selectedImageCollectionView.numberOfItems(inSection: 0) == 0 {
//                self.selectedImageCollectionViewHeightConstraint.constant = 0
//                self.updateViewConstraints()
                animator.startAnimation()
            }
        }
    }
    
    
    private func changeTemporaryOrderIndex(in collectionView: UICollectionView, from fromIndex: Int, to destinationIndex: Int, animatingDifferences: Bool) {
        
        var imageEntityArray = self.imageEntityManager.getImageEntities(from: self.selectedMemoEntity, inOrderOf: ImageOrderIndexKind.temporaryOrderIndex, isTemporaryDeleted: false)
        
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




extension MemoEditingViewController: UICollectionViewDataSource {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let categoryEntityArray = self.categoryEntityManager.getCategoryEntities(inOrderOf: CategoryProperties.modificationDate, isAscending: false)
        return categoryEntityArray.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard collectionView == self.categoryListCollectionView else {
            fatalError("unknown collection view has set dataSource delegate to self")
        }
        
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MemoDetailViewCategoryListCell.cellID, for: indexPath) as! MemoDetailViewCategoryListCell
        let categoryEntity = self.categoryEntityArray[indexPath.row]
        
        cell.configureCell(with: categoryEntity)
        
        if self.temporaryCategorySet.contains(categoryEntity) {
            self.categoryListCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .init())
        } else {
            self.categoryListCollectionView.deselectItem(at: indexPath, animated: true)
        }
        
        return cell
    }
    
}

extension MemoEditingViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == self.selectedImageCollectionView {
            
            //            let imageEntityToShow = self.imageEntityManager.getImageEntities(from: self.selectedMemoEntity, inOrderOf: ImageOrderIndexKind.temporaryOrderIndex, isTemporaryDeleted: false)[indexPath.row]
            //            let imageToShow = self.imageEntityManager.getImage(imageEntity: imageEntityToShow)
            //            let selectedImageVC = DetailViewSelectedImageViewController(image: imageToShow)
            //            selectedImageVC.modalPresentationStyle = .formSheet
            //            self.present(selectedImageVC, animated: true)
            
            let temporaryImageEntitiesArray = ImageEntityManager.shared.getImageEntities(
                from: self.selectedMemoEntity,
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
            
        } else if collectionView == self.categoryListCollectionView {
            
            let selectedCategory = self.categoryEntityArray[indexPath.row]
            switch self.temporaryCategorySet.insert(selectedCategory).inserted {
            case true:
                print("selectedCategory has inserted into temporary category set.")
            case false:
                fatalError("inserting selectedCategory into temporary category set failed.")
            }
            self.setupToolbar()
            
        } else {
            fatalError()
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if collectionView == self.categoryListCollectionView {
            
            let categoryEntityToRemove = self.categoryEntityArray[indexPath.row]
            self.temporaryCategorySet.remove(categoryEntityToRemove)
            self.setupToolbar()
        }
    }
}


extension MemoEditingViewController: UICollectionViewDragDelegate {
    
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



extension MemoEditingViewController: UICollectionViewDropDelegate {
    
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




extension MemoEditingViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        picker.dismiss(animated: true)
        var index: Int = self.thumbnailArray.count
        var countDown: Int = results.count
        guard results.count != 0 else { return }
        self.completeBarButtonItem.isEnabled = false
        self.photoBarButtonItem.isEnabled = false
        self.selectedImageCollectionViewTopConstraint.constant = 17
        self.selectedImageCollectionViewHeightConstraint.constant = CGSizeConstant.detailViewThumbnailSize.height
        self.selectedImageCollectionView.isScrollEnabled = false
        self.selectedImageCollectionView.alpha = 0.3
        self.activityIndicatorView.startAnimating()
        
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
                    let _ = self.imageEntityManager.createImageEntity(image: image, orderIndex: index, memoEntity: self.selectedMemoEntity, isTemporaryAppended: true)
                    
                    countDown -= 1
                    if countDown == 0 {
                        DispatchQueue.main.async { [weak self] in
                            guard let self else { fatalError() }
//                            self.selectedImageCollectionViewHeightConstraint.constant = CGSizeConstant.compositionalCardThumbnailSize.height
                            self.applySnapshot(animatingDifferences: true, usingReloadData: false) { [weak self] in
                                guard let self else { fatalError() }
                                
                                self.completeBarButtonItem.isEnabled = true
                                self.photoBarButtonItem.isEnabled = true
                                self.activityIndicatorView.stopAnimating()
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
                    let _ = self.imageEntityManager.createImageEntity(image: webpToUIImage, orderIndex: index, memoEntity: self.selectedMemoEntity, isTemporaryAppended: true)
                    
                    countDown -= 1
                    
                    //가장 늦게 로드된 사진이 작업을 끝마치면 다음 코드 실행
                    if countDown == 0 {
                        DispatchQueue.main.async { [weak self] in
                            guard let self else { fatalError() }
//                            self.selectedImageCollectionViewHeightConstraint.constant = CGSizeConstant.compositionalCardThumbnailSize.height
                            self.applySnapshot(animatingDifferences: true, usingReloadData: false) { [weak self] in
                                guard let self else { fatalError() }
                                self.completeBarButtonItem.isEnabled = true
                                self.photoBarButtonItem.isEnabled = true
                                self.activityIndicatorView.stopAnimating()
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
            }
            index += 1
        }
    }
}


extension MemoEditingViewController: UIViewControllerTransitioningDelegate {
    
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
