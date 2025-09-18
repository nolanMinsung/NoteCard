//
//  MemoDetailViewController.swift
//  NoteCard
//
//  Created by 김민성 on 9/11/25.
//

import UIKit

class MemoDetailViewController: UIViewController {
    
    enum MemoDetailType {
        case making
        case editing(memo: Memo, images: [ImageUIModel])
    }
    
    private let rootView = MemoDetailView()
    private let detailType: MemoDetailType
    private let memo: Memo?
    private var categories: [Category] = []
    private var selectedCategories: [Category] = []
    private var imageModels: [any TemporaryImageInfo] = []
    
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
            self.imageModels = imageModels.sorted(by: { $0.temporaryOrderIndex < $1.temporaryOrderIndex })
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
        
        setupDelegates()
        Task {
            guard let memo else { return }
            do {
                try await configureView(with: memo)
            } catch {
                print(error.localizedDescription)
            }
        }
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
            print("완료 bar button item이 눌렸다!")
        }
        completeBarButtonItem.primaryAction = completeAction
        
        
        let selectImageAction = UIAction(image: UIImage(systemName: "photo")) { _ in
            print("이미지 선택 bar button item이 눌렸다!")
        }
        imageBarButtonItem.primaryAction = selectImageAction
    }
    
    func setupDelegates() {
        rootView.categoryListCollectionView.dataSource = self
        rootView.imageCollectionView.dataSource = self
        rootView.imageCollectionView.delegate = self
        rootView.imageCollectionView.dragDelegate = self
        rootView.imageCollectionView.dropDelegate = self
    }
    
    func configureView(with memo: Memo) async throws {
        // configuring title
        rootView.titleTextField.text = memo.memoTitle
        
        // configuring category
        categories = try await CategoryEntityRepository.shared.getAllCategories(
            inOrderOf: .modificationDate,
            isAscending: false
        )
        selectedCategories = memo.categories.sorted(by: { $0.modificationDate > $1.modificationDate })
        rootView.categoryListCollectionView.reloadData()
        categories
            .enumerated()
            .filter { selectedCategories.contains($0.element) }
            .forEach {
                let indexPath = IndexPath(item: $0.offset, section: 0)
                rootView.categoryListCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .init())
            }
        
        rootView.imageCollectionView.reloadData()
        if imageModels.isEmpty {
            rootView.hideImageCollectionView()
        } else {
            rootView.showImageCollectionView(targetHeight: CGSizeConstant.detailViewThumbnailSize.height)
        }
        rootView.memoTextView.text = memo.memoText
    }
    
}


// MARK: - UICollectionViewDataSource
extension MemoDetailViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == rootView.categoryListCollectionView {
            return categories.count
        } else if collectionView == rootView.imageCollectionView {
            return imageModels.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == rootView.categoryListCollectionView {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MemoDetailViewCategoryListCell.cellID,
                for: indexPath
            ) as! MemoDetailViewCategoryListCell
            cell.configureCell(with: categories[indexPath.item])
            return cell
        } else if collectionView == rootView.imageCollectionView {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MemoDetailViewSelectedImageCell.cellID,
                for: indexPath
            ) as! MemoDetailViewSelectedImageCell
            cell.configureCell(with: imageModels[indexPath.item])
            return cell
        } else {
            fatalError()
        }
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
            let images = imageModels.map(\.originalImage)
            let imageShowingVC = CardImageShowingViewController(indexPath: indexPath, images: images)
            imageShowingVC.modalPresentationStyle = .overFullScreen
            present(imageShowingVC, animated: true)
        }
    }
    
}


// MARK: - UICollectionViewDragDelegate
extension MemoDetailViewController: UICollectionViewDragDelegate {
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: any UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = imageModels[indexPath.item]
        let dummyItemProvider = NSItemProvider(object: item.originalImageID.uuidString as NSItemProviderWriting)
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
//    
//    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnter session: any UIDropSession) {
//        <#code#>
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, dropSessionDidExit session: any UIDropSession) {
//        <#code#>
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: any UIDropSession) {
//        <#code#>
//    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: any UICollectionViewDropCoordinator) {
        return
    }
    
}
