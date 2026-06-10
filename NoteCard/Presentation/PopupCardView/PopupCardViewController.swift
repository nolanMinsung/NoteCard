//
//  PopupCardViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import AnalyticsInterface
import Combine
import Data
import Domain
import DesignSystem
import Shared
import UIKit

class PopupCardViewController: UIViewController {
    
    let rootView: PopupCardView
    private lazy var memoTextView = rootView.memoTextView
    private let memoTextViewTapGesture = UITapGestureRecognizer()
    
    private var memo: Memo
    private var categories: [Domain.Category] = []
    private var popupImageItems: [PopupImageItem] = [] {
        didSet {
            rootView.imageCollectionViewHeight.constant = popupImageItems.isEmpty ? 0 : 70
            rootView.setNeedsLayout()
        }
    }
    
    private var editingEnabled: Bool

    private let environment: AppEnvironment

    private var restoreMemoAction: UIAction!
    private var presentEditingModeAction: UIAction!
    private var deleteMemoAction: UIAction!
    private var searchInThisMemoAction: UIAction!
    private var cancellables = Set<AnyCancellable>()

    @Published private var inMemoSearchQuery: String = ""
    private var matchRanges: [NSRange] = []
    private var currentMatchIndex: Int = 0
    private var isInMemoSearchActive = false
    
    init(memo: Memo, indexPath: IndexPath, editingEnabled: Bool = true, environment: AppEnvironment) {
        self.memo = memo
        self.environment = environment
        self.rootView = PopupCardView(memo: self.memo, environment: environment)
        self.editingEnabled = editingEnabled
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
                self.rootView.categoryCollectionView.reloadData()
            } catch {
                print("PopupCard 카테고리 fetch 실패: \(error)")
            }
            await self.loadImageItems()
        }
        
        rootView.memoTextView.addGestureRecognizer(memoTextViewTapGesture)
        memoTextViewTapGesture.addTarget(self, action: #selector(memoTextViewTapped(_:)))
        memoTextViewTapGesture.isEnabled = false
        rootView.memoTextView.isEditable = true
        
        if !editingEnabled {
            rootView.likeButton.isEnabled = false
            rootView.ellipsisButton.isEnabled = false
            rootView.titleTextField.isUserInteractionEnabled = false
            rootView.titleTextField.textColor = .secondaryLabel
            rootView.memoTextView.isSelectable = false
            rootView.memoTextView.textColor = .secondaryLabel
            rootView.memoTextView.isEditable = false
            memoTextViewTapGesture.isEnabled = false
        }
        
        setupInMemoSearch()

        // PopupCard 표시 중에만 해당 메모의 image sub-collection listener attach.
        // cancellables 라이프사이클에 묶여 dismiss 시 자동 detach.
        environment.imageRepository.observeImageChanges(for: memo.memoID)
            .store(in: &cancellables)

        environment.imageRepository.imageUpdatedPublisher
            .filter { [weak self] updateType in
                guard let self else { return false }
                return updateType.memoID == self.memo.memoID
            }
            .receive(on: RunLoop.main)
            // 한 메모 안의 여러 이미지를 순회하며 업데이트하므로, 짧은 시간에 여러 연속적인 이벤트가 발생함.
            // 동시에 여러 이벤트를 연속적으로 받아오면서 받은 이벤트 횟수만큼 이미지를 불러오고 reloadData 하는 현상이 발생
            // 부하를 막기 위해 debounce 사용.
            // (debounce 없으면 에러 발생)
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task {
                    await self.loadImageItems()
                }
            }
            .store(in: &cancellables)

        let initialIsInTrash = memo.isInTrash
        environment.memoRepository.memoUpdatedPublisher
            .filter({ [weak self] updateType in
                guard let self else { return false }
                return updateType.memoIDs.contains(self.memo.memoID)
            })
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task {
                    do {
                        let updatedMemo = try await self.environment.memoRepository.getMemo(id: self.memo.memoID)
                        // 다른 기기에서 휴지통 → 복원으로 모드가 뒤집힌 경우. UI를 그 자리에서
                        // 재구성하기 복잡해서 그냥 닫는다 (사용자는 해당 메모를 새 위치에서 다시 열 수 있음).
                        guard updatedMemo.isInTrash == initialIsInTrash else {
                            self.dismiss(animated: true)
                            return
                        }
                        self.memo = updatedMemo
                        self.categories = try await self.fetchCategories()

                        // 통합 갱신 — 직접 title / memoText 만 set 하면 memoDateLabel (~~에 수정됨) 과
                        // likeButton.isSelected (다른 기기에서 즐겨찾기 토글) 가 stale 로 남는다.
                        self.rootView.configureView(with: updatedMemo)
                        self.rootView.categoryCollectionView.reloadData()
                    } catch RepositoryError.notFound {
                        self.dismiss(animated: true)
                    } catch {
                        print("PopupCard 메모 업데이트 실패: \(error)")
                    }
                }
            }
            .store(in: &cancellables)

        environment.categoryRepository.categoryUpdatedPublisher
            .filter { [weak self] updateType in
                guard let self else { return false }
                let memoCategoryIDs = Set(self.memo.categories.map(\.id))
                return updateType.categoryIDs.contains(where: memoCategoryIDs.contains)
            }
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task {
                    do {
                        self.categories = try await self.fetchCategories()
                        self.rootView.categoryCollectionView.reloadData()
                    } catch {
                        print("PopupCard 카테고리 갱신 실패: \(error)")
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        environment.analytics.log(.screenView(.memoCard))

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
        } completion: { [weak self] _ in
            guard let self else { return }
            guard editingEnabled else { return }
            self.memoTextViewTapGesture.isEnabled = true
        }
    }
    
    private func setupDelegates() {
        self.rootView.categoryCollectionView.dataSource = self
        self.rootView.imageCollectionView.dataSource = self
        self.rootView.imageCollectionView.delegate = self
        self.rootView.memoTextView.delegate = self
        self.rootView.titleTextField.delegate = self
    }
    
}


// MARK: - Initial Settings
private extension PopupCardViewController {
    
    func setupActions() {
        restoreMemoAction = UIAction(
            title: L10n.PopupCard.recoverAsUncategorizedSingle,
            image: .init(systemName: "arrow.counterclockwise"),
            handler: { [weak self] action in
                guard let self else { fatalError() }
                self.askRestoring()
            }
        )
        
        presentEditingModeAction = UIAction(
            title: L10n.Common.editingMode,
            image: UIImage(systemName: "pencil"),
            handler: { [weak self] action in
                guard let self else { return }
                Task { await self.enterEditingMode() }
            }
        )
        
        deleteMemoAction = UIAction(
            title: L10n.PopupCard.deleteThisMemo,
            image: UIImage(systemName: "trash"),
            attributes: UIMenuElement.Attributes.destructive,
            handler: { [weak self] action in
                guard let self else { return }
                self.askDeleting()
            }
        )

        searchInThisMemoAction = UIAction(
            title: L10n.PopupCard.searchInThisMemo,
            image: UIImage(systemName: "magnifyingglass"),
            handler: { [weak self] action in
                guard let self else { return }
                self.enterInMemoSearchMode()
            }
        )

        rootView.titleTextField.addTarget(self, action: #selector(titleTextFieldEditingDidEndOnExit), for: .editingDidEndOnExit)
    }
    
    @objc private func titleTextFieldEditingDidEndOnExit(_ sender: UITextField) {
        sender.endEditing(true)
        guard sender.text != memo.memoTitle else {
            return
        }
        Task {
            do {
                try await environment.memoRepository.updateMemoContent(memo, newTitle: sender.text, newMemoText: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    
    func setupButtonsAction() {
        if memo.isInTrash {
            rootView.ellipsisButton.menu = UIMenu(children: [restoreMemoAction, deleteMemoAction])
            rootView.titleTextField.isUserInteractionEnabled = false
            rootView.memoTextView.isUserInteractionEnabled = false
        } else {
            rootView.ellipsisButton.menu = UIMenu(children: [searchInThisMemoAction, presentEditingModeAction, deleteMemoAction])
        }
        rootView.likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
    }
    
}


private extension PopupCardViewController {
    
    @objc func likeButtonTapped() {
        Task {
            do {
                try await environment.memoRepository.setFavorite(memo, to: !memo.isFavorite)
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
            return popupImageItems.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.rootView.categoryCollectionView {
            guard let cell = self.rootView.categoryCollectionView.dequeueReusableCell(
                withReuseIdentifier: PopupCategoryCell.reuseIdentifier,
                for: indexPath
            ) as? PopupCategoryCell
            else {
                fatalError()
            }
            let category = categories[indexPath.item]
            cell.configure(with: category)
            return cell
        } else {
            let cell = self.rootView.imageCollectionView.dequeueReusableCell(
                withReuseIdentifier: PopupImageCell.cellID,
                for: indexPath
            ) as! PopupImageCell
            let item = popupImageItems[indexPath.item]
            let imageID = item.info.id
            cell.configure(state: item.thumbnailState) { [weak self] in
                Task { await self?.retryThumbnail(forImageID: imageID) }
            }
            return cell
        }
    }
    
}


// MARK: - UICollectionViewDelegate
extension PopupCardViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.view.endEditing(true)
        let infos = popupImageItems.map(\.info)
        let cardImageShowingVC = CardImageShowingViewController(
            indexPath: indexPath,
            imageInfos: infos,
            imageRepository: environment.imageRepository
        )
        cardImageShowingVC.modalPresentationStyle = .overFullScreen
        self.present(cardImageShowingVC, animated: true)
    }
    
}


// MARK: - UITextViewDelegate
extension PopupCardViewController: UITextViewDelegate {
    
    func textViewDidEndEditing(_ textView: UITextView) {
        memoTextViewTapGesture.isEnabled = true
        guard textView.text != memo.memoText else {
            return
        }
        Task {
            do {
                try await environment.memoRepository.updateMemoContent(memo, newTitle: nil, newMemoText: textView.text)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
}


extension PopupCardViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let trimmedInput = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        textField.text = trimmedInput
        guard trimmedInput != memo.memoTitle else {
            return
        }
        Task {
            do {
                try await environment.memoRepository.updateMemoContent(memo, newTitle: trimmedInput, newMemoText: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
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
            memoTextViewTapGesture.isEnabled = false
        }
    }
    
    
}


// MARK: - In-Memo Search

private extension PopupCardViewController {

    func setupInMemoSearch() {
        rootView.inMemoSearchBar.onQueryChanged = { [weak self] query in
            self?.inMemoSearchQuery = query
        }
        rootView.inMemoSearchBar.onTapPrevious = { [weak self] in
            self?.moveToPreviousMatch()
        }
        rootView.inMemoSearchBar.onTapNext = { [weak self] in
            self?.moveToNextMatch()
        }
        rootView.inMemoSearchBar.onTapClose = { [weak self] in
            self?.exitInMemoSearchMode()
        }

        $inMemoSearchQuery
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.runInMemoSearch(query: query)
            }
            .store(in: &cancellables)
    }

    func enterInMemoSearchMode() {
        guard !isInMemoSearchActive else { return }
        isInMemoSearchActive = true

        // 본문 bottom 을 검색바 top 으로 끌어올린(push-up) 뒤 검색바를 first responder 로 만들어 키보드를 띄운다.
        // 제약 변경을 pending 으로 둔 채 키보드를 올려, 검색바 등장과 본문 축소가 키보드 애니메이션에 함께 실리게 한다.
        rootView.showInMemoSearchBar()
        rootView.inMemoSearchBar.focusTextField()

        // 검색 중에는 본문 편집을 잠가 일치 위치(NSRange)가 무효화되지 않도록 한다.
        // (검색바가 first responder 를 가져가므로 키보드는 그대로 유지된다.)
        rootView.memoTextView.isEditable = false
        memoTextViewTapGesture.isEnabled = false
    }

    func exitInMemoSearchMode() {
        guard isInMemoSearchActive else { return }
        isInMemoSearchActive = false

        clearMatchHighlights()
        inMemoSearchQuery = ""
        rootView.inMemoSearchBar.reset()

        // 검색바를 떼어내며 키보드가 내려가고, pending 된 제약 변경(본문이 다시 늘어남)이 그 애니메이션에 함께 실린다.
        // 본문은 top 기준이라 아래로 늘어나도 컨텐츠 offset 이 튀지 않는다.
        rootView.hideInMemoSearchBar()

        if editingEnabled {
            rootView.memoTextView.isEditable = true
            memoTextViewTapGesture.isEnabled = true
        }
    }

    func runInMemoSearch(query: String) {
        // 검색 모드가 아닐 때(예: 화면 진입 직후 @Published 초기값 방출)는 본문을 건드리지 않는다.
        guard isInMemoSearchActive else { return }
        guard !query.isEmpty else {
            clearMatchHighlights()
            rootView.inMemoSearchBar.updateCount(current: 0, total: 0)
            rootView.inMemoSearchBar.setLoading(false)
            return
        }

        rootView.inMemoSearchBar.setLoading(true)
        let text = rootView.memoTextView.text ?? ""

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let ranges = Self.matchRanges(of: query, in: text)
            DispatchQueue.main.async {
                guard let self else { return }
                // 결과를 기다리는 사이 검색어가 또 바뀌었다면, 곧 새 검색이 다시 갱신하므로 이번 결과는 버린다.
                guard query == self.inMemoSearchQuery else { return }
                self.applyMatches(ranges)
                self.rootView.inMemoSearchBar.setLoading(false)
            }
        }
    }

    func applyMatches(_ ranges: [NSRange]) {
        matchRanges = ranges
        currentMatchIndex = 0
        applyMatchHighlights()
        if !ranges.isEmpty {
            scrollToCurrentMatch()
        }
        updateMatchCount()
    }

    func moveToNextMatch() {
        guard !matchRanges.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + 1) % matchRanges.count
        applyMatchHighlights()
        scrollToCurrentMatch()
        updateMatchCount()
    }

    func moveToPreviousMatch() {
        guard !matchRanges.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex - 1 + matchRanges.count) % matchRanges.count
        applyMatchHighlights()
        scrollToCurrentMatch()
        updateMatchCount()
    }

    func applyMatchHighlights() {
        let textStorage = rootView.memoTextView.textStorage
        let fullRange = NSRange(location: 0, length: textStorage.length)
        let normalColor = UIColor.currentTheme.withAlphaComponent(0.5)
        let currentColor = UIColor.currentTheme.withAlphaComponent(0.85)

        textStorage.beginEditing()
        textStorage.removeAttribute(.backgroundColor, range: fullRange)
        for (index, range) in matchRanges.enumerated() {
            let highlightColor = index == currentMatchIndex ? currentColor : normalColor
            textStorage.addAttribute(.backgroundColor, value: highlightColor, range: range)
        }
        textStorage.endEditing()
    }

    func clearMatchHighlights() {
        matchRanges = []
        currentMatchIndex = 0
        // 배경색 제거가 스크롤 위치를 흔들지 않도록 offset 을 보존한다.
        let savedOffset = rootView.memoTextView.contentOffset
        let textStorage = rootView.memoTextView.textStorage
        let fullRange = NSRange(location: 0, length: textStorage.length)
        textStorage.removeAttribute(.backgroundColor, range: fullRange)
        rootView.memoTextView.contentOffset = savedOffset
    }

    func scrollToCurrentMatch() {
        guard matchRanges.indices.contains(currentMatchIndex) else { return }
        rootView.memoTextView.scrollRangeToVisible(matchRanges[currentMatchIndex])
    }

    func updateMatchCount() {
        let current = matchRanges.isEmpty ? 0 : currentMatchIndex + 1
        rootView.inMemoSearchBar.updateCount(current: current, total: matchRanges.count)
    }

    /// 표시 중인 본문에서 검색어와 일치하는 모든 NSRange 를 찾는다.
    /// NSString 기준으로 탐색해 한글 등 결합 문자에서도 하이라이트 범위가 어긋나지 않도록 한다.
    static func matchRanges(of query: String, in text: String) -> [NSRange] {
        guard !query.isEmpty else { return [] }
        let nsText = text as NSString
        var ranges: [NSRange] = []
        var searchStart = 0
        while searchStart < nsText.length {
            let remainingRange = NSRange(location: searchStart, length: nsText.length - searchStart)
            let foundRange = nsText.range(of: query, options: [.caseInsensitive], range: remainingRange)
            if foundRange.location == NSNotFound {
                break
            }
            ranges.append(foundRange)
            searchStart = foundRange.location + max(foundRange.length, 1)
        }
        return ranges
    }

}


// MARK: - Domain.Category Fetching
private extension PopupCardViewController {
    
    private func fetchCategories() async throws -> [Domain.Category] {
        return try await environment.categoryRepository.getAllCategories(
            ofMemo: memo,
            inOrderOf: .modificationDate,
            isAscending: false
        )
    }
    
}


// MARK: - 이미지 lazy 로딩
private extension PopupCardViewController {

    /// 메타만 받아 placeholder 즉시 노출 → 각 thumbnail 비동기 병렬 로드.
    /// 로컬 캐시 hit 이면 sync 로 즉시 .loaded 로 표시 (스피너 거치지 않음).
    /// 메모 자체가 trash 등으로 사라진 경우 dismiss.
    func loadImageItems() async {
        let infos: [MemoImageInfo]
        do {
            infos = try await environment.imageRepository.getAllImageInfo(for: memo)
        } catch RepositoryError.notFound {
            self.dismiss(animated: true)
            return
        } catch {
            print("PopupCard 이미지 메타 fetch 실패: \(error)")
            return
        }

        popupImageItems = infos.map { info in
            if let cached = ImageLoadingHelper.loadCachedImage(for: info, thumbnail: true) {
                return PopupImageItem(info: info, thumbnailState: .loaded(cached))
            }
            return PopupImageItem(info: info, thumbnailState: .loading)
        }
        rootView.imageCollectionView.reloadData()

        for item in popupImageItems {
            if case .loading = item.thumbnailState {
                Task { await self.loadThumbnail(forImageID: item.info.id) }
            }
        }
    }

    /// retry 버튼에서 호출. state 를 .loading 으로 되돌리고 다시 로드.
    func retryThumbnail(forImageID imageID: UUID) async {
        guard let index = popupImageItems.firstIndex(where: { $0.info.id == imageID }) else { return }
        popupImageItems[index].thumbnailState = .loading
        rootView.imageCollectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
        await loadThumbnail(forImageID: imageID)
    }

    /// 편집 진입 — MemoDetailVC 가 원본 + 썸네일 둘 다 필요한 ImageUIModel 을 요구하므로
    /// 모든 이미지를 sync 로 받아서 변환 후 진입. 한 장이라도 실패하면 alert.
    func enterEditingMode() async {
        // 편집 모드(formSheet)로 넘어가기 전에 검색 모드를 정리한다.
        // 그대로 두면 편집 후 돌아왔을 때 stale 한 검색 상태(하이라이트·일치 위치)가 남는다.
        exitInMemoSearchMode()

        do {
            let models = try await fetchAllImageUIModelsForEditing()
            let memoEditingVC = MemoDetailViewController(
                type: .editing(memo: memo, images: models),
                environment: environment
            )
            let naviCon = UINavigationController(rootViewController: memoEditingVC)
            naviCon.modalPresentationStyle = .formSheet
            self.present(naviCon, animated: true)
        } catch {
            print("PopupCard 편집 진입 위한 이미지 로드 실패: \(error)")
            let alert = UIAlertController(
                title: L10n.PopupCard.editingPreloadFailedTitle,
                message: L10n.PopupCard.editingPreloadFailedMessage,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
            self.present(alert, animated: true)
        }
    }

    private func fetchAllImageUIModelsForEditing() async throws -> [ImageUIModel] {
        let infos = popupImageItems.map(\.info)
        let imageRepository = environment.imageRepository
        return try await withThrowingTaskGroup(of: (Int, ImageUIModel).self) { group in
            for (index, info) in infos.enumerated() {
                group.addTask {
                    let original = try await imageRepository.getImage(from: info)
                    let thumbnail = try await imageRepository.getThumbnailImage(from: info)
                    return (index, ImageUIModel(from: info, image: original, thumbnail: thumbnail))
                }
            }
            var results: [Int: ImageUIModel] = [:]
            for try await (index, model) in group {
                results[index] = model
            }
            return results.sorted { $0.key < $1.key }.map { $0.value }
        }
    }

    /// 단일 thumbnail 로드. transient 실패에 대응해 자동 재시도 (exponential backoff).
    /// 끝까지 실패 시 state = .failed → 셀에 재시도 버튼 노출.
    func loadThumbnail(forImageID imageID: UUID) async {
        guard let info = popupImageItems.first(where: { $0.info.id == imageID })?.info else { return }
        let imageRepository = environment.imageRepository

        let result = await ImageLoadingHelper.loadWithRetry {
            try await imageRepository.getThumbnailImage(from: info)
        }

        guard let index = popupImageItems.firstIndex(where: { $0.info.id == imageID }) else { return }
        switch result {
        case .success(let image):
            popupImageItems[index].thumbnailState = .loaded(image)
        case .failure(let error):
            print("PopupCard thumbnail 로드 실패 (\(imageID)): \(error)")
            popupImageItems[index].thumbnailState = .failed
        }
        rootView.imageCollectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
    }
}


extension PopupCardViewController {
    
    func askRestoring() {
        rootView.endEditing(true)
        
        let alertCon = UIAlertController(
            title: L10n.PopupCard.recoverThisMemoConfirm,
            message: L10n.PopupCard.recoverThisMemoMessage,
            preferredStyle: UIAlertController.Style.alert
        )
        let cancelAction = UIAlertAction(title: L10n.Common.cancel, style: .cancel)
        let restoreAction = UIAlertAction(title: L10n.Common.recover, style: .default) { action in
            Task{
                do {
                    try await self.environment.memoRepository.restore(self.memo)
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
        let title = (memo.isInTrash ? L10n.PopupCard.deleteSelectedMemoConfirm : L10n.PopupCard.deleteMemoTitle)
        let message = (memo.isInTrash ? L10n.Common.actionCannotBeUndone : L10n.PopupCard.deleteMemoConfirm)
        let alertstyle: UIAlertController.Style = memo.isInTrash ? .actionSheet : .alert
        let alertCon = UIAlertController(title: title, message: message, preferredStyle: alertstyle)
        alertCon.view.tintColor = .currentTheme
        if alertstyle == .actionSheet {
            // iPad 에서 actionSheet 는 popover 로 표시되므로 anchor 가 없으면 crash.
            // 메뉴를 띄운 ellipsisButton 자리에서 popover 가 나오게 anchor 지정.
            alertCon.popoverPresentationController?.sourceView = rootView.ellipsisButton
            alertCon.popoverPresentationController?.sourceRect = rootView.ellipsisButton.bounds
        }
        
        let cancelAction = UIAlertAction(title: L10n.Common.cancel, style: .cancel)
        let deleteAction = UIAlertAction(title: L10n.Common.delete, style: .destructive) { [weak self] action in
            guard let self else { return }
            let memo = self.memo
            let env = self.environment
            let isInTrash = memo.isInTrash
            self.dismiss(animated: true)
            Task {
                do {
                    if isInTrash {
                        try await env.memoRepository.deleteMemo(memo)
                        env.analytics.log(.memoDeleted(count: 1))
                    } else {
                        try await env.memoRepository.moveToTrash(memo)
                        env.analytics.log(.memoMovedToTrash(count: 1))
                    }
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
