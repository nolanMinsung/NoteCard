//
//  MemoSearchingViewController.swift
//  NoteCard
//
//  Created by 김민성 on 8/6/25.
//

import AnalyticsInterface
import Combine
import Data
import Domain
import DesignSystem
import Shared
import UIKit

import Wisp

class MemoSearchingViewController: UIViewController {
    
    let rootView = MemoSearchingView()

    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @Published
    private var searchText: String = ""
    private var diffableDataSource: UICollectionViewDiffableDataSource<Int, Memo>!
    private var cancellables = Set<AnyCancellable>()
    
    override func loadView() {
        view = rootView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        environment.analytics.log(.screenView(.search))
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
        appearance.backgroundColor = .memoViewBackground
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        navigationItem.title = L10n.TabBar.searchMemo
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
                    let memoSearchResult = try await self.environment.memoRepository.searchMemo(searchText: searchText)
                    self.applySnapshot(with: memoSearchResult)
                }
            }
            .store(in: &cancellables)
        
        ThemeManager.shared.currentThemePublisher
            .sink { [weak self] _ in
                self?.rootView.collectionView.visibleCells.forEach { cell in
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
            environment: environment
        )
        
        let topInset: CGFloat
        if #available(iOS 26.0, *), [.pad, .vision].contains(UIDevice.current.userInterfaceIdiom) {
            topInset = splitViewController?.view.safeAreaInsets.top ?? view.safeAreaInsets.top
        } else {
            topInset = tabBarController?.view.safeAreaInsets.top ?? view.safeAreaInsets.top
        }
        
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
