//
//  MemoDetailViewController.swift
//  NoteCard
//
//  Created by 김민성 on 9/11/25.
//

import Combine
import CoreData
import UIKit

class MemoDetailViewController: UIViewController {
    
    typealias DiffableDataSource = UICollectionViewDiffableDataSource<Section, EditableImageItem>
    typealias ImageDataSnapshot = NSDiffableDataSourceSnapshot<Section, EditableImageItem>
    
    enum MemoDetailType {
        case making(category: Category?)
        case editing(memo: Memo, images: [ImageUIModel])
    }
    
    enum Section {
        case main
    }
    
    private let rootView = MemoDetailView()
    private let detailType: MemoDetailType
    private var memo: Memo?
    private var categories: [Category] = []
    private var selectedCategories: [Category] = []
    private var editableImageModels: [EditableImageItem] = []
    private var dataSource: DiffableDataSource!
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - UI Properties
    
    private let cancelBarButtonItem = UIBarButtonItem()
    private let completeBarButtonItem = UIBarButtonItem()
    private let imageBarButtonItem = UIBarButtonItem()
    private var labelBarButtonItem: UIBarButtonItem {
        let label = UILabel()
        label.textColor = .label
        label.numberOfLines = 1
        label.text = String(format: "%d개의 카테고리 선택됨".localized(), 0 /*self.categoryListCollectionView.indexPathsForSelectedItems?.count ?? 999*/)
        let item = UIBarButtonItem(customView: label)
        return item
    }
    
    init(type: MemoDetailType) {
        self.detailType = type
        if case .editing(let memo, let imageModels) = type {
            self.memo = memo
            self.editableImageModels = imageModels
                .sorted { $0.temporaryOrderIndex < $1.temporaryOrderIndex }
                .map { .existing(model: $0) }
        } else {
            self.memo = nil
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = rootView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        setupToolbar()
        setupBarButtonActions()
        navigationItem.leftBarButtonItem = cancelBarButtonItem
        navigationItem.rightBarButtonItem = completeBarButtonItem
        
        setupActions()
        setupDiffableDataSource()
        setupDelegates()
        Task {
            do {
                categories = try await CategoryEntityRepository.shared.getAllCategories(
                    inOrderOf: .modificationDate,
                    isAscending: false
                )
                rootView.categoryListCollectionView.reloadData()
                applyImageDataSnapshot()
                configureInitialTexts()
                selectInitialCategories()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        rootView.prepareForDismissal()
    }
    
}


// MARK: - Initial Settings
private extension MemoDetailViewController {
    
    func setupToolbar() {
        navigationController?.isToolbarHidden = false
        toolbarItems = [
            imageBarButtonItem,
            UIBarButtonItem(systemItem: .flexibleSpace),
            labelBarButtonItem,
            UIBarButtonItem(systemItem: .flexibleSpace),
        ]
    }
    
    func setupBarButtonActions() {
        let cancelAction = UIAction(title: "취소".localized()) { [weak self] _ in
            guard let self else { return }
            self.dismiss(animated: true)
        }
        cancelBarButtonItem.primaryAction = cancelAction
        
        let completeAction = UIAction(title: "완료".localized()) { _ in
            Task {
                do {
                    try await self.updateMemoContent()
                    try await self.updateImages()
                    try await self.updateCategories()
                    self.dismiss(animated: true)
                } catch {
                    assertionFailure("에러 발생")
                }
            }
        }
        completeBarButtonItem.primaryAction = completeAction
        
        
        let selectImageAction = UIAction(image: UIImage(systemName: "photo")) { _ in
            print("이미지 선택 bar button item이 눌렸다!")
        }
        imageBarButtonItem.primaryAction = selectImageAction
    }
    
    func setupActions() {
        rootView.memoTextView.textPublisher
            .receive(on: RunLoop.main)
            .map(\.isEmpty)
            .map({ return !$0 })
            .assign(to: \.isHidden, on: rootView.textPlaceholderLabel)
            .store(in: &cancellables)
    }
    
    func setupDiffableDataSource() {
        dataSource = DiffableDataSource(
            collectionView: rootView.imageCollectionView,
            cellProvider: { collectionView, indexPath, itemIdentifier in
                let cellReuseID = MemoDetailViewSelectedImageCell.reuseIdentifier
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: cellReuseID,
                    for: indexPath
                ) as? MemoDetailViewSelectedImageCell else {
                    fatalError()
                }
                cell.configureCell(with: itemIdentifier)
                return cell
            }
        )
    }
    
    func applyImageDataSnapshot() {
        var snapshot = ImageDataSnapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(editableImageModels, toSection: .main)
        dataSource.apply(snapshot)
        
        if editableImageModels.isEmpty {
            rootView.hideImageCollectionView()
        } else {
            rootView.showImageCollectionView(targetHeight: CGSizeConstant.detailViewThumbnailSize.height)
        }
    }
    
    func setupDelegates() {
        rootView.categoryListCollectionView.dataSource = self
        rootView.imageCollectionView.delegate = self
        rootView.imageCollectionView.dragDelegate = self
        rootView.imageCollectionView.dropDelegate = self
    }
    
    func selectInitialCategories() {
        switch detailType {
        case .making(let category):
            if let category {
                selectedCategories = [category]
            }
        case .editing(let memo, _):
            selectedCategories = memo.categories.sorted(by: { $0.modificationDate > $1.modificationDate })
        }
        categories
            .enumerated()
            .filter { selectedCategories.contains($0.element) }
            .forEach {
                let indexPath = IndexPath(item: $0.offset, section: 0)
                rootView.categoryListCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .init())
            }
        
    }
    
    func configureInitialTexts() {
        guard let memo else { return }
        rootView.titleTextField.text = memo.memoTitle
        rootView.memoTextView.text = memo.memoText
        rootView.textPlaceholderLabel.isHidden = !memo.memoText.isEmpty
    }
    
}


// MARK: - 변경 내용 업데이트
private extension MemoDetailViewController {
    
    func updateMemoContent() async throws {
        let newTitle = rootView.titleTextField.text
        let newMemoText = rootView.memoTextView.text
        
        switch detailType {
        case .editing(let memo, _):
            try await MemoEntityRepository.shared.updateMemoContent(
                memo,
                newTitle: newTitle,
                newMemoText: newMemoText
            )
            if let newTitle { self.memo?.memoTitle = newTitle }
            if let newMemoText { self.memo?.memoText = newMemoText }
        case .making:
            let newMemo = try await MemoEntityRepository.shared.createNewMemo()
            try await MemoEntityRepository.shared.updateMemoContent(
                newMemo,
                newTitle: newTitle,
                newMemoText: newMemoText
            )
            self.memo = newMemo
        }
    }
    
    func updateCategories() async throws {
        guard let memo  else {
            print("메모가 생성되기 전에 이미지 저장 시도!")
            throw CoreDataError.objectNotFound
        }
        let selectedCategoryIndexes = (rootView.categoryListCollectionView.indexPathsForSelectedItems ?? []).map { $0.item }
        let selectedCategories = categories.enumerated()
            .filter { selectedCategoryIndexes.contains($0.offset) }
            .map(\.element)
        
        try await MemoEntityRepository.shared.replaceCategories(to: memo, newCategories: Set(selectedCategories))
    }
    
    func updateImages() async throws {
        guard let memo else {
            print("메모가 생성되기 전에 이미지 저장 시도!")
            throw CoreDataError.objectNotFound
        }
        try await withThrowingTaskGroup(of: Void.self) { group in
            let currentImageItems = dataSource.snapshot().itemIdentifiers
            for (index, item) in currentImageItems.enumerated() {
                group.addTask {
                    switch item {
                    case .existing(model: let model):
                        /**
                         `model`은 `ImageUIModel` 타입
                         `model`을 바탕으로 `ImageEntity`를 불러온 후 이 레코드의 `index`를 `item.offset`으로 업데이트
                         */
                        try await ImageEntityRepository.shared.updateImageIndex(model.info, newIndex: index)
                    case .pendingAddition(model: let model):
                        /**
                         `model`은 `ImageUITemporaryModel` 타입
                         `model`을 바탕으로 새 이미지 파일과 `ImageEntity`를 생성한 후에 각각 `FileManager`, `CoreData`에 저장.
                         저장 시 index 정보는 `item.offset`
                         */
                        let _ = try await ImageEntityRepository.shared.createImage(
                            from: model.pickerResult,
                            for: memo,
                            orderIndex: index,
                            isTemporary: false
                        )
                    case .pendingDeletion(model: let model):
                        /**
                         `model`은 `ImageUIModel` 타입
                         model을 바탕으로 `ImageEntity`를 불러온 후 이 이 레코드의 데이터 및 이미지 파일 삭제
                         */
                        try await ImageEntityRepository.shared.deleteImage(model.info)
                    }
                }
            }
        }
    }
    
}


// MARK: - UICollectionViewDataSource
extension MemoDetailViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MemoDetailViewCategoryListCell.cellID,
            for: indexPath
        ) as! MemoDetailViewCategoryListCell
        cell.configureCell(with: categories[indexPath.item])
        return cell
    }
    
}


// MARK: - 이미지 가져오기
extension MemoDetailViewController {
    
//    @objc private func presentphPickerVC() { }
    
}


// MARK: - UICollectionViewDelegate
extension MemoDetailViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == rootView.imageCollectionView {
            let images = editableImageModels.map(\.model.originalImage)
            let imageShowingVC = CardImageShowingViewController(indexPath: indexPath, images: images)
            imageShowingVC.modalPresentationStyle = .overFullScreen
            present(imageShowingVC, animated: true)
        }
    }
    
}


// MARK: - UICollectionViewDragDelegate
extension MemoDetailViewController: UICollectionViewDragDelegate {
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: any UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = editableImageModels[indexPath.item]
        let dummyItemProvider = NSItemProvider(object: item.model.originalImageID.uuidString as NSItemProviderWriting)
        let dragItem = UIDragItem(itemProvider: dummyItemProvider)
        dragItem.localObject = item
        return [dragItem]
    }
    
}


// MARK: - UICollectionViewDropDelegate
extension MemoDetailViewController: UICollectionViewDropDelegate {
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: any UIDropSession) -> Bool {
        return (session.localDragSession != nil)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: any UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UICollectionViewDropProposal {
        guard session.localDragSession != nil else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: any UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }
        coordinator.items.forEach { dropItem in
            guard let sourceIndexPath = dropItem.sourceIndexPath else { return }
            
            let movedItem = editableImageModels.remove(at: sourceIndexPath.item)
            editableImageModels.insert(movedItem, at: destinationIndexPath.item)
            self.applyImageDataSnapshot()
            coordinator.drop(dropItem.dragItem, toItemAt: destinationIndexPath)
        }
    }
    
}
