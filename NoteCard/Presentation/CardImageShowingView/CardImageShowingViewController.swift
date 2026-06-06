//
//  CardImageShowingViewController.swift
//  CardMemo
//

import Data
import DesignSystem
import Domain
import Shared
import UIKit

class CardImageShowingViewController: UIViewController {

    private enum Source {
        /// PopupCard 경로 — 서버에서 lazy 로드.
        case lazy(infos: [MemoImageInfo], repository: ImageRepository)
        /// MemoDetail (편집 중) 경로 — 이미 받은 이미지 직접 표시.
        case eager(images: [UIImage])
    }

    private let initialIndexPath: IndexPath
    private let source: Source
    private var imageStates: [UUID: ImageLoadState] = [:]
    private var eagerIDs: [UUID] = []

    private let rootView = CardImageShowingView()

    /// Lazy: PopupCard 에서 메모 셀 탭 시 사용. 로컬 캐시 hit 이면 즉시 .loaded, 아니면 .loading.
    init(indexPath: IndexPath, imageInfos: [MemoImageInfo], imageRepository: ImageRepository) {
        self.initialIndexPath = indexPath
        self.source = .lazy(infos: imageInfos, repository: imageRepository)
        for info in imageInfos {
            if let cached = ImageLoadingHelper.loadCachedImage(for: info, thumbnail: false) {
                self.imageStates[info.id] = .loaded(cached)
            } else {
                self.imageStates[info.id] = .loading
            }
        }
        super.init(nibName: nil, bundle: nil)
    }

    /// Eager: MemoDetail (편집 중) 에서 이미 받은 이미지로 표시. lazy 로딩 / 재시도 흐름 적용 X.
    init(indexPath: IndexPath, images: [UIImage]) {
        self.initialIndexPath = indexPath
        self.source = .eager(images: images)
        self.eagerIDs = images.map { _ in UUID() }
        for (id, image) in zip(eagerIDs, images) {
            self.imageStates[id] = .loaded(image)
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

        setupDelegates()
        rootView.dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)

        if case .lazy(let infos, _) = source {
            for info in infos {
                if case .loaded = imageStates[info.id] { continue }
                Task { await self.loadImage(forImageID: info.id) }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        rootView.imageCollectionView.scrollToItem(at: initialIndexPath, at: .centeredHorizontally, animated: false)
        rootView.imageCollectionView.alpha = 1.0
    }

    private func setupDelegates() {
        rootView.imageCollectionView.dataSource = self
    }

    @objc private func dismissButtonTapped() {
        dismiss(animated: true)
    }

    private func retryImage(forImageID imageID: UUID) async {
        imageStates[imageID] = .loading
        reloadCell(forImageID: imageID)
        await loadImage(forImageID: imageID)
    }

    private func loadImage(forImageID imageID: UUID) async {
        guard case .lazy(let infos, let imageRepository) = source,
              let info = infos.first(where: { $0.id == imageID }) else { return }
        let result = await ImageLoadingHelper.loadWithRetry {
            try await imageRepository.getImage(from: info)
        }
        switch result {
        case .success(let image):
            imageStates[imageID] = .loaded(image)
        case .failure(let error):
            print("CardImageShowing 원본 로드 실패 (\(imageID)): \(error)")
            imageStates[imageID] = .failed
        }
        reloadCell(forImageID: imageID)
    }

    private func reloadCell(forImageID imageID: UUID) {
        let index: Int?
        switch source {
        case .lazy(let infos, _):
            index = infos.firstIndex(where: { $0.id == imageID })
        case .eager:
            index = eagerIDs.firstIndex(of: imageID)
        }
        guard let index else { return }
        rootView.imageCollectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
    }

    private func imageID(at index: Int) -> UUID? {
        switch source {
        case .lazy(let infos, _):
            guard index < infos.count else { return nil }
            return infos[index].id
        case .eager:
            guard index < eagerIDs.count else { return nil }
            return eagerIDs[index]
        }
    }
}


// MARK: - UICollectionViewDataSource
extension CardImageShowingViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch source {
        case .lazy(let infos, _): return infos.count
        case .eager(let images): return images.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.rootView.imageCollectionView.dequeueReusableCell(
            withReuseIdentifier: CardImageShowingCollectionViewCell.cellID,
            for: indexPath
        ) as! CardImageShowingCollectionViewCell
        guard let id = imageID(at: indexPath.item) else { return cell }
        let state = imageStates[id] ?? .loading
        cell.configure(state: state) { [weak self] in
            Task { await self?.retryImage(forImageID: id) }
        }
        return cell
    }
}
