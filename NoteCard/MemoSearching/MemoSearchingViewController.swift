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
    
    private let favoriteMemoArray: [MemoEntity] = {
        return MemoEntityManager.shared.getFavoriteMemoEntities()
    }()
    
    var diffableDataSource: UICollectionViewDiffableDataSource<Int, MemoEntity>? = nil
    
    override func loadView() {
        view = rootView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        diffableDataSource = UICollectionViewDiffableDataSource<Int, MemoEntity>(
            collectionView: rootView.collectionView)
        { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MemoSearchingCell", for: indexPath) as? MemoSearchingCell else {
                fatalError()
            }
            cell.configure(title: itemIdentifier.memoTitle, memoTextBuffer: itemIdentifier.memoTextShortBuffer)
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
        var snapshot = NSDiffableDataSourceSnapshot<Int, MemoEntity>()
        snapshot.appendSections([0])
        snapshot.appendItems(favoriteMemoArray)
        diffableDataSource?.apply(snapshot)
    }
    
}


// MARK: - UICollectionViewDelegate
extension MemoSearchingViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let popupVC = PopupCardViewController(
            memo: favoriteMemoArray[indexPath.item],
            selectedCollectionViewCell: .init(),
            indexPath: indexPath,
            selectedCellFrame: .zero,
            cornerRadius: .zero,
            isInteractive: false
        )
        
        let wispConfiguration = WispConfiguration(
            presentedAreaInset: .init(top: 100, left: 10, bottom: 100, right: 10),
            initialCornerRadius: 25,
            finalCornerRadius: 25,
        )
        
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
