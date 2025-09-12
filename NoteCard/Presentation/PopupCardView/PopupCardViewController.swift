//
//  PopupCardViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class PopupCardViewController: UIViewController {
    
    let rootView: PopupCardView
    lazy var memoTextView = rootView.memoTextView
    let memoTextViewTapGesture = UITapGestureRecognizer()
    
    let memo: Memo
    private var categories: [Category] = []
    private var imageUIModels: [ImageUIModel] = [] {
        didSet {
            self.rootView.selectedImageCollectionViewHeightConstraint.constant
            = imageUIModels.isEmpty ? 0 : 70
            self.rootView.setNeedsLayout()
        }
    }
    
    var isMemoDeleted: Bool = false
    
    lazy var restoreMemoAction = UIAction(
        title: "카테고리 없는 메모로 복구".localized(),
        image: .init(systemName: "arrow.counterclockwise")?.withTintColor(.currentTheme, renderingMode: .alwaysOriginal),
        handler: { [weak self] action in
            guard let self else { fatalError() }
            self.askRestoring()
        }
    )
    
    lazy var presentEditingModeAction = UIAction(
        title: "편집 모드".localized(),
        image: UIImage(systemName: "pencil"),
        handler: { [weak self] action in
            guard let self else { return }
            
            let memoEditingVC = MemoDetailViewController(type: .editing, memo: memo)
            let naviCon = UINavigationController(rootViewController: memoEditingVC)
            naviCon.modalPresentationStyle = .formSheet
            self.present(naviCon, animated: true)
        }
    )
    
    lazy var deleteMemoAction = UIAction(
        title: "이 메모 삭제하기".localized(),
        image: UIImage(systemName: "trash"),
        attributes: UIMenuElement.Attributes.destructive,
        handler: { [weak self] action in
            guard let self else { return }
            self.askDeleting()
        }
    )
    
    init(memo: Memo, indexPath: IndexPath, enableEditing: Bool = true) {
        self.memo = memo
        self.rootView = PopupCardView(memo: self.memo)
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
        
        setupDelegates()
        Task {
            do {
                self.categories = try await self.fetchCategories()
                self.imageUIModels = try await self.makeImageUIModels()
                
                self.rootView.categoryCollectionView.reloadData()
                self.rootView.imageCollectionView.reloadData()
            } catch {
                assertionFailure("메모의 카테고리 혹은 이미지를 가져오는 데 에러 발생!!!")
            }
        }
        
        if memo.isInTrash {
            rootView.ellipsisButton.menu = UIMenu(children: [self.restoreMemoAction, self.deleteMemoAction])
        } else {
            rootView.ellipsisButton.menu = UIMenu(children: [self.presentEditingModeAction, self.deleteMemoAction])
        }
        
        rootView.likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        
        rootView.memoTextView.addGestureRecognizer(self.memoTextViewTapGesture)
        memoTextViewTapGesture.addTarget(self, action: #selector(memoTextViewTapped(_:)))
        
        rootView.memoTextView.isSelectable = false
        memoTextViewTapGesture.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        rootView.memoTextViewBottomConstraints.isActive = false
        rootView.memoTextViewBottomConstraintsToKeyboard.isActive = true
        memoTextViewTapGesture.isEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.rootView.isTextViewChanged {
            self.rootView.updateMemoTextView()
        }
    }
    
    private func setupDelegates() {
        self.rootView.categoryCollectionView.dataSource = self
        self.rootView.imageCollectionView.dataSource = self
        self.rootView.imageCollectionView.delegate = self
    }
    
}


private extension PopupCardViewController {
    
    @objc func likeButtonTapped() {
        Task {
            do {
                try await MemoEntityRepository.shared.setFavorite(memo, to: !memo.isFavorite)
                rootView.likeButton.isSelected.toggle()
            }
        }
    }
    
}


// MARK: - UICollectionViewDataSource

extension PopupCardViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.rootView.categoryCollectionView {
            return categories.count
        } else {
            return imageUIModels.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.rootView.categoryCollectionView {
            guard let cell = self.rootView.categoryCollectionView.dequeueReusableCell(
                withReuseIdentifier: TotalListCellCategoryCell.cellID,
                for: indexPath
            ) as? TotalListCellCategoryCell
            else {
                fatalError()
            }
            let category = categories[indexPath.item]
            cell.configure(with: category)
            return cell
        } else {
            let cell = self.rootView.imageCollectionView.dequeueReusableCell(
                withReuseIdentifier: MemoImageCollectionViewCell.cellID,
                for: indexPath
            ) as! MemoImageCollectionViewCell
            cell.configure(with: imageUIModels[indexPath.item])
            return cell
        }
    }
    
}


// MARK: - UICollectionViewDelegate
extension PopupCardViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.view.endEditing(true)
        let images = imageUIModels.map(\.originalImage)
        let cardImageShowingVC = CardImageShowingViewController(indexPath: indexPath, images: images)
        cardImageShowingVC.modalPresentationStyle = .overFullScreen
        self.present(cardImageShowingVC, animated: true)
    }
    
}


// MARK: - text view tap Gesture
extension PopupCardViewController {
    
    @objc private func memoTextViewTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: rootView.memoTextView)
        
        if let position = rootView.memoTextView.closestPosition(to: location) {
            rootView.memoTextView.isEditable = true
            rootView.memoTextView.selectedTextRange = rootView.memoTextView.textRange(from: position, to: position)
            rootView.memoTextView.becomeFirstResponder()
        }
    }
    
    
}


// MARK: - Category Fetching
private extension PopupCardViewController {
    
    private func fetchCategories() async throws -> [Category] {
        return try await CategoryEntityRepository.shared.getAllCategories(
            ofMemo: memo,
            inOrderOf: .modificationDate,
            isAscending: false
        )
    }
    
}


// MARK: - Fetching Image Model And Make UIModels
private extension PopupCardViewController {
    
    private func makeImageUIModels() async throws -> [ImageUIModel] {
        var imageUIModels: [ImageUIModel] = []
        
        let fetchedImageInfoList = try await ImageEntityRepository.shared.getAllImageInfo(for: memo)
        let fetchedThumbnails = try await fetchThumbnailsConcurrently(for: fetchedImageInfoList)
        let fetchedImages = try await fetchImagesConcurrently(for: fetchedImageInfoList)
        
        guard fetchedImageInfoList.count == fetchedImages.count,
              fetchedImageInfoList.count == fetchedThumbnails.count
        else {
            throw ImageFileError.fileNotFound
        }
        
        for imageInfo in fetchedImageInfoList.enumerated() {
            let imageUIModel = ImageUIModel(
                from: imageInfo.element,
                image: fetchedImages[imageInfo.offset],
                thumbnail: fetchedThumbnails[imageInfo.offset]
            )
            imageUIModels.append(imageUIModel)
        }
        return imageUIModels
    }
    
    private func fetchThumbnailsConcurrently(for imageInfos: [MemoImageInfo]) async throws -> [UIImage] {
        var thumbnailResults: [Int: UIImage] = [:]
        try await withThrowingTaskGroup(of: (Int, UIImage).self) { group in
            for (index, info) in imageInfos.enumerated() {
                group.addTask {
                    let thumbnail = try await ImageEntityRepository.shared.getThumbnailImage(from: info)
                    return (index, thumbnail)
                }
            }
            for try await (index, thumbnail) in group {
                thumbnailResults[index] = thumbnail
            }
        }
        return thumbnailResults.sorted { $0.key < $1.key }.map { $0.value }
    }
    
    private func fetchImagesConcurrently(for imageInfos: [MemoImageInfo]) async throws -> [UIImage] {
        var imageResults: [Int: UIImage] = [:]
        try await withThrowingTaskGroup(of: (Int, UIImage).self) { group in
            for (index, info) in imageInfos.enumerated() {
                group.addTask {
                    let image = try await ImageEntityRepository.shared.getImage(from: info)
                    return (index, image)
                }
            }
            for try await (index, image) in group {
                imageResults[index] = image
            }
        }
        return imageResults.sorted { $0.key < $1.key }.map { $0.value }
    }
    
}
