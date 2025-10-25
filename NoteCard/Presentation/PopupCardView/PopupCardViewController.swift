//
//  PopupCardViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import Combine
import UIKit

class PopupCardViewController: UIViewController {
    
    let rootView: PopupCardView
    private lazy var memoTextView = rootView.memoTextView
    private let memoTextViewTapGesture = UITapGestureRecognizer()
    
    private let memo: Memo
    private var categories: [Category] = []
    private var imageUIModels: [ImageUIModel] = [] {
        didSet {
            rootView.imageCollectionViewHeight.constant = imageUIModels.isEmpty ? 0 : 70
            rootView.setNeedsLayout()
        }
    }
    
    private var isMemoDeleted: Bool = false
    
    private var restoreMemoAction: UIAction!
    private var presentEditingModeAction: UIAction!
    private var deleteMemoAction: UIAction!
    private var cancellables = Set<AnyCancellable>()
    
    init(memo: Memo, indexPath: IndexPath, enableEditing: Bool = true) {
        self.memo = memo
        self.rootView = PopupCardView(memo: self.memo)
        super.init(nibName: nil, bundle: nil)
        
        setupActions()
        setupButtonsAction()
        setupDelegates()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = rootView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        rootView.memoTextView.addGestureRecognizer(memoTextViewTapGesture)
        memoTextViewTapGesture.addTarget(self, action: #selector(memoTextViewTapped(_:)))
        memoTextViewTapGesture.isEnabled = false
        rootView.memoTextView.isEditable = true
        
        MemoEntityRepository.shared.memoUpdatedPublisher
            .filter({ updateType in
                guard case .update(_) = updateType else { return false }
                return true
            })
            .sink { [weak self] _ in
            guard let self else { return }
            
            Task {
                do {
                    let updatedMemo = try await MemoEntityRepository.shared.getMemo(id: self.memo.memoID)
                    self.imageUIModels = try await self.makeImageUIModels()
                    self.categories = try await self.fetchCategories()
                    
                    self.rootView.categoryCollectionView.reloadData()
                    self.rootView.imageCollectionView.reloadData()
                    self.rootView.titleTextField.text = updatedMemo.memoTitle
                    self.rootView.memoTextView.text = updatedMemo.memoText
                    print("popupCard의 콘텐츠 업데이트")
                } catch {
                    assertionFailure("변경된 메모 데이터를 업데이트 하는데 에러 발생!!!")
                }
            }
        }
        .store(in: &cancellables)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 1,
            options: [.allowUserInteraction]
        ) { [weak self] in
            guard let self else { return }
            self.rootView.memoTextViewBottom.isActive = false
            self.rootView.memoTextViewBottomToKeyboardTop.isActive = true
            self.rootView.layoutIfNeeded()
        }
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


// MARK: - Initial Settings
private extension PopupCardViewController {
    
    func setupActions() {
        restoreMemoAction = UIAction(
            title: "카테고리 없는 메모로 복구".localized(),
            image: .init(systemName: "arrow.counterclockwise"),
            handler: { [weak self] action in
                guard let self else { fatalError() }
                self.askRestoring()
            }
        )
        
        presentEditingModeAction = UIAction(
            title: "편집 모드".localized(),
            image: UIImage(systemName: "pencil"),
            handler: { [weak self] action in
                guard let self else { return }
                
                let memoEditingVC = MemoDetailViewController(
                    type: .editing(memo: self.memo, images: self.imageUIModels)
                )
                let naviCon = UINavigationController(rootViewController: memoEditingVC)
                naviCon.modalPresentationStyle = .formSheet
                self.present(naviCon, animated: true)
            }
        )
        
        deleteMemoAction = UIAction(
            title: "이 메모 삭제하기".localized(),
            image: UIImage(systemName: "trash"),
            attributes: UIMenuElement.Attributes.destructive,
            handler: { [weak self] action in
                guard let self else { return }
                self.askDeleting()
            }
        )
    }
    
    func setupButtonsAction() {
        if memo.isInTrash {
            rootView.ellipsisButton.menu = UIMenu(children: [restoreMemoAction, deleteMemoAction])
        } else {
            rootView.ellipsisButton.menu = UIMenu(children: [presentEditingModeAction, deleteMemoAction])
        }
        rootView.likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
    }
    
}


private extension PopupCardViewController {
    
    @objc func likeButtonTapped() {
        Task {
            do {
                try await MemoEntityRepository.shared.setFavorite(memo, to: !memo.isFavorite)
                rootView.likeButton.isSelected.toggle()
            } catch {
                print(error.localizedDescription)
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


// MARK: - Fetching Image Model And Making UIModels
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


extension PopupCardViewController {
    
    func askRestoring() {
        rootView.endEditing(true)
        
        let alertCon = UIAlertController(
            title: "이 메모를 복구하시겠습니까?".localized(),
            message: "복구된 메모는 '카테고리 없음' 항목에서 확인할 수 있습니다.".localized(),
            preferredStyle: UIAlertController.Style.alert
        )
        let cancelAction = UIAlertAction(title: "취소".localized(), style: .cancel)
        let restoreAction = UIAlertAction(title: "복구".localized(), style: .default) { action in
            Task{
                do {
                    try await MemoEntityRepository.shared.restore(self.memo)
                    self.dismiss(animated: true)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        alertCon.addAction(cancelAction)
        alertCon.addAction(restoreAction)
        
        self.present(alertCon, animated: true)
    }
    
    func askDeleting() {
        self.rootView.endEditing(true)
        let title = (memo.isInTrash ? "선택한 메모를 영구적으로 삭제하시겠습니까?".localized() : "메모 삭제".localized())
        let message = (memo.isInTrash ? "이 동작은 취소할 수 없습니다.".localized() : "메모를 삭제하시겠습니까?".localized())
        let alertstyle: UIAlertController.Style = memo.isInTrash ? .actionSheet : .alert
        let alertCon = UIAlertController(title: title, message: message, preferredStyle: alertstyle)
        alertCon.view.tintColor = .currentTheme
        
        let cancelAction = UIAlertAction(title: "취소".localized(), style: .cancel)
        let deleteAction = UIAlertAction(title: "삭제".localized(), style: .destructive) { [weak self] action in
            guard let self else { return }
            Task {
                do {
                    if self.memo.isInTrash {
                        try await MemoEntityRepository.shared.deleteMemo(self.memo)
                    } else {
                        try await MemoEntityRepository.shared.moveToTrash(self.memo)
                    }
                    self.dismiss(animated: true)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        alertCon.addAction(cancelAction)
        alertCon.addAction(deleteAction)
        self.present(alertCon, animated: true)
    }
    
}
