//
//  MemoSearchingViewController.swift
//  NoteCard
//
//  Created by 김민성 on 8/6/25.
//

import UIKit

import Wisp

class MemoSearchingViewController: UIViewController {
    
    let rootView = MemoSearchingView()
    
//    private let favoriteMemoArray: [MemoEntity] = {
//        return MemoEntityManager.shared.getFavoriteMemoEntities()
//    }()
    
    private var favoriteMemoArray: [MemoPreviewDTO]!
    
    var diffableDataSource: UICollectionViewDiffableDataSource<Int, MemoPreviewDTO>? = nil
    
    override func loadView() {
        view = rootView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        favoriteMemoArray = MemoEntityManager.shared.getFavoriteMemoEntities().map({
            MemoPreviewDTO(from: $0)
        })
        setupNaviBar()
        setupDiffableDataSource()
        setupDelegates()
        applySnapshot()
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
        diffableDataSource = UICollectionViewDiffableDataSource<Int, MemoPreviewDTO>(
            collectionView: rootView.collectionView)
        { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MemoSearchingCell", for: indexPath) as? MemoSearchingCell else {
                fatalError()
            }
            cell.configure(title: itemIdentifier.memoTitlePreview, memoTextBuffer: itemIdentifier.memoTextPreview)
            return cell
        }
    }
    
    func setupDelegates() {
        rootView.collectionView.delegate = self
        rootView.searchBar.searchTextField.delegate = self
    }
    
}


private extension MemoSearchingViewController {
    
    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, MemoPreviewDTO>()
        snapshot.appendSections([0])
        snapshot.appendItems(favoriteMemoArray)
        diffableDataSource?.apply(snapshot)
    }
    
}


// MARK: - UICollectionViewDelegate
extension MemoSearchingViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let memoIDToOpen = favoriteMemoArray[indexPath.item].memoID
        let memoToOpen = MemoEntityManager.shared.getSpecificMemoEntity(memoID: memoIDToOpen)
        let popupVC = PopupCardViewController(
            memo: memoToOpen,
            indexPath: indexPath,
        )
        
        let topInset = tabBarController?.view.safeAreaInsets.top ?? view.safeAreaInsets.top
        let inset: UIEdgeInsets = ((indexPath.item % 2 == 0)
                                            ? .init(top: 130, left: 10, bottom: 130, right: 10)
                                            : .init(top: topInset, left: 0, bottom: 0, right: 0))
        
        let wispConfiguration = WispConfiguration { config in
            config.setLayout { layout in
                layout.presentedAreaInset = inset
                layout.initialCornerRadius = 25
                layout.finalCornerRadius = 25
            }
        }
        
        wisp.present(popupVC, collectionView: rootView.collectionView, at: indexPath, configuration: wispConfiguration)
    }
    
}


extension MemoSearchingViewController: UITextFieldDelegate {
    
    
    
}


// MARK: - UISearchBarDelegate
extension MemoSearchingViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print(#function, searchText)
    }
    
}
