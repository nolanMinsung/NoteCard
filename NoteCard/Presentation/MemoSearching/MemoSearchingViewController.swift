//
//  MemoSearchingViewController.swift
//  NoteCard
//
//  Created by 김민성 on 8/6/25.
//

import Combine
import UIKit

import Wisp

class MemoSearchingViewController: UIViewController {
    
    let rootView = MemoSearchingView()
    
    @Published
    private var searchText: String = ""
    private var diffableDataSource: UICollectionViewDiffableDataSource<Int, Memo>!
    private var cancellables = Set<AnyCancellable>()
    
    override func loadView() {
        view = rootView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNaviBar()
        setupDiffableDataSource()
        setupDelegates()
        rootView.searchBar.searchTextField.addTarget(self, action: #selector(textFieldEditing), for: .allEditingEvents)
        bind()
    }
    
    @objc private func textFieldEditing(_ sender: UITextField) {
        print(#function)
        searchText = sender.text ?? ""
    }
    
}


private extension MemoSearchingViewController {
    
    func setupNaviBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        navigationItem.title = "메모 검색".localized()
    }
    
    func setupDiffableDataSource() {
        rootView.collectionView.register(MemoSearchingCell.self, forCellWithReuseIdentifier: "MemoSearchingCell")
        diffableDataSource = UICollectionViewDiffableDataSource<Int, Memo>(
            collectionView: rootView.collectionView
        ) { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MemoSearchingCell", for: indexPath) as? MemoSearchingCell else {
                fatalError()
            }
            cell.configure(memo: itemIdentifier)
            return cell
        }
    }
    
    func setupDelegates() {
        rootView.collectionView.delegate = self
        wisp.delegate = self
    }
    
    func bind() {
        $searchText
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .sink { searchText in
                Task {
                    let memoSearchResult = try await MemoEntityRepository.shared.searchMemo(searchText: searchText)
                    self.applySnapshot(with: memoSearchResult)
                }
            }
            .store(in: &cancellables)
        
        ThemeManager.shared.currentThemePublisher
            .sink { [weak self] _ in
                guard let self else { return }
                rootView.collectionView.visibleCells.forEach { cell in
                    // 테마 색에 맞게 그림자를 그리는 작업이 layoutSubviews에서 진행되기 때문...
                    cell.setNeedsLayout()
                }
            }
            .store(in: &cancellables)
    }
    
}


private extension MemoSearchingViewController {
    
    func applySnapshot(with memoList: [Memo]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Memo>()
        snapshot.appendSections([0])
        snapshot.appendItems(memoList)
        diffableDataSource?.apply(snapshot)
    }
    
}


// MARK: - UICollectionViewDelegate
extension MemoSearchingViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedMemo = diffableDataSource.itemIdentifier(for: indexPath) else {
            return
        }
        let popupVC = PopupCardViewController(
            memo: selectedMemo,
            indexPath: indexPath,
        )
        
        let topInset = tabBarController?.view.safeAreaInsets.top ?? view.safeAreaInsets.top
        
        let wispConfiguration = WispConfiguration { config in
            config.setAnimation { animation in
                animation.speed = .fast
            }
            config.setLayout { layout in
                layout.presentedAreaInset = .init(top: topInset, left: 0, bottom: 0, right: 0)
                layout.initialCornerRadius = 25
                layout.finalCornerRadius = 25
            }
        }
        
        wisp.present(popupVC, collectionView: rootView.collectionView, at: indexPath, configuration: wispConfiguration)
    }
    
}


// MARK: - UISearchBarDelegate
extension MemoSearchingViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print(#function, searchText)
    }
    
}


extension MemoSearchingViewController: WispPresenterDelegate {
    
    func wispWillRestore() {
        return
    }
    
    func wispDidRestore() {
        searchText = searchText // just trigger
    }
    
}
