//
//  TotalListTableViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/17.
//

import Combine
import UIKit

class TotalListViewController: UIViewController {
    
    enum TotalListCollectionViewSection: CaseIterable {
        case main
    }
    
    //MARK: -
//    enum TotalListTableViewSection: CaseIterable {
//        case main
//    }
    
    let memoEntityManager = MemoEntityManager.shared
    
    lazy var totalListView = self.view as! TotalListView
    
    lazy var totalListCollectionView = self.totalListView.totalListCollectionView
    
    var userDefaultCriterion: String? { UserDefaults.standard.string(forKey: UserDefaultsKeys.orderCriterion.rawValue) }
    
//    var percentDrivenInteractiveTransition: PercentDrivenInteractiveTransition?
    var memoEntitySearhResult: [MemoEntity] = []
    var selectedIndexPath: IndexPath?
    
    private var cancellables: Set<AnyCancellable> = []
    
    override func loadView() {
        self.view = TotalListView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNaviBar()
        setupDelegates()
//        setupInteractiveTransition()
        setupObserver()
//        updateSearchResult()
        self.memoEntitySearhResult = []
        self.definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("totalListVC", #function)
        super.viewWillAppear(animated)
        guard let searchController = self.navigationItem.searchController else { fatalError() }
//        if searchController.isActive {
//            guard let searchText = self.navigationItem.searchController?.searchBar.text else { fatalError() }
        
    }
    
    
    
    
    
    private func setupNaviBar() {
        
        self.title = "메모 검색".localized()
        
        let appearance = UINavigationBarAppearance()
//        appearance.configureWithOpaqueBackground()
        appearance.configureWithDefaultBackground()
//        appearance.configureWithTransparentBackground()
//        appearance.backgroundColor = .systemGray5
        
        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.navigationController?.navigationBar.compactAppearance = appearance
        self.navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
        
        let searchController = UISearchController()
        searchController.searchBar.delegate = self
        
        let bar = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        let hideKeyboardButton = UIBarButtonItem(image: UIImage(systemName: "keyboard.chevron.compact.down"), style: .plain, target: self, action: #selector(keyboardHideButtonTapped))
        let flexibleBarButton = UIBarButtonItem(systemItem: UIBarButtonItem.SystemItem.flexibleSpace)
        bar.items = [flexibleBarButton, hideKeyboardButton]
        bar.sizeToFit()
        bar.tintColor = .currentTheme
        searchController.searchBar.tintColor = .currentTheme
        searchController.searchBar.inputAccessoryView = bar
        
        self.navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
//        self.navigationItem.searchController?.isActive = false
        self.navigationItem.searchController?.hidesNavigationBarDuringPresentation = true
        self.navigationController?.navigationBar.tintColor = .label
    }
    
    @objc private func keyboardHideButtonTapped() {
        self.navigationItem.searchController?.searchBar.endEditing(true)
    }
    
    
    
    private func setupDelegates() {
        
        self.totalListCollectionView.dataSource = self
        self.totalListCollectionView.delegate = self
        
    }
    
//    private func setupInteractiveTransition() {
//        self.percentDrivenInteractiveTransition = PercentDrivenInteractiveTransition(viewController: self)
//    }
    
    private func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(presentPopupCardVC(_:)), name: NSNotification.Name("cellSelectedNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(memoCreated(_:)), name: NSNotification.Name("createdMemoNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(memoEdited(_:)), name: Notification.Name("editingCompleteNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(memoSentToTrash(_:)), name: NSNotification.Name("memoTrashedNotification"), object: nil)
        
        ThemeManager.shared.currentThemeSubject.sink { [weak self] color in
            self?.themeColorChanged()
        }.store(in: &cancellables)
        
//        NotificationCenter.default.addObserver(self, selector: #selector(memoRecoveredToUncategorized(_:)), name: NSNotification.Name("memoRecoveredToUncategorizedNotification"), object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { fatalError() }
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? CGFloat else { fatalError() }
    }
    
    @objc private func presentPopupCardVC(_ notification: Notification) {
        print(#function)
        
        guard let searchController = self.navigationItem.searchController else { fatalError() }
        if searchController.searchBar.searchTextField.isEditing {
           return
        }
        
        guard let cell = notification.userInfo?["cell"] as? TotalListCollectionViewCell else { return }
        
        
        guard let memoEntity = cell.memoEntity else { return }
        guard let selectedIndexPath = self.totalListCollectionView.indexPath(for: cell) else { return }
        
        self.selectedIndexPath = selectedIndexPath
        let convertedRect = cell.convert(cell.contentView.frame, to: self.view)
        let popupCardVC = PopupCardViewController(memo: memoEntity.toDomain(),  indexPath: selectedIndexPath)
        popupCardVC.modalPresentationStyle = .custom
        
        self.tabBarController?.present(popupCardVC, animated: true)
        
    }
    
    
    @objc private func memoCreated(_ notification: Notification) {
        guard let createdMemoEntity = notification.userInfo?["memo"] as? MemoEntity else { fatalError() }
        guard let isOrderAscending = UserDefaults.standard.value(forKey: UserDefaultsKeys.isOrderAscending.rawValue) as? Bool else { fatalError() }
        guard let searchCon = self.navigationItem.searchController else { fatalError() }
        let searchText = searchCon.searchBar.text!
        
        guard !searchText.isEmpty else { return }
        
        self.updateSearchResult()
        guard self.memoEntitySearhResult.contains(createdMemoEntity) else { return }
        if isOrderAscending {
            self.totalListCollectionView.insertItems(
                at: [IndexPath(item: self.totalListCollectionView.numberOfItems(inSection: 0), section: 0)]
            )
            if totalListCollectionView.indexPathsForVisibleItems.contains(
                where:
                    { [weak self] indexPath in
                        guard let self else { fatalError() }
                        return indexPath.item == self.totalListCollectionView.numberOfItems(inSection: 0) - 1 }) {
                
                self.totalListCollectionView.scrollToItem(
                    at: IndexPath(item: self.totalListCollectionView.numberOfItems(inSection: 0) - 1, section: 0),
                    at: UICollectionView.ScrollPosition.top,
                    animated: true
                )
            }
            
        } else {
            self.totalListCollectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
        }
        
    }
    
    
    @objc private func memoEdited(_ notification: Notification) {
        print(#function)
        guard let editedMemo = notification.userInfo?["memo"] as? MemoEntity else { fatalError() }
//        guard let searchCon = self.navigationItem.searchController else { fatalError() }
//        guard let selectedIndexPath else { fatalError() }
//        let searchText = searchCon.searchBar.text!
        guard let indexToUpdate = self.memoEntitySearhResult.firstIndex(of: editedMemo) else { return }
        let indexPathToUpdate = IndexPath(item: indexToUpdate, section: 0)
        self.totalListCollectionView.reloadItems(at: [indexPathToUpdate])
        
    }
    
    
    
    @objc private func memoSentToTrash(_ notification: Notification) {
        var indexPathsToDelete: [IndexPath] = []
        guard let deletedMemoEntities = notification.userInfo?["trashedMemos"] as? [MemoEntity] else { fatalError() }
        deletedMemoEntities.forEach { memoEntityToDelete in
            if let indexToDelete = self.memoEntitySearhResult.firstIndex(of: memoEntityToDelete) {
                indexPathsToDelete.append(IndexPath(item: indexToDelete, section: 0))
            }
        }
        
        //스크롤 시 끊기는 현상이 나타날 수 있기 때문에 updateDataSource 대신 각 indexPath를 이용해 직접 지워줌
        let indexesToDelete = indexPathsToDelete.map({ $0.item })
        self.memoEntitySearhResult = self.memoEntitySearhResult
            .enumerated()
            .filter({ !indexesToDelete.contains($0.offset) })
            .map({ $0.element })
        
        self.totalListCollectionView.deleteItems(at: indexPathsToDelete)
    }
    
    
    @objc private func themeColorChanged() {
        guard let searchCon = self.navigationItem.searchController else { fatalError() }
        searchCon.searchBar.tintColor = .currentTheme
        searchCon.searchBar.inputAccessoryView?.tintColor = .currentTheme
        
        self.totalListCollectionView.reloadItems(at: self.totalListCollectionView.indexPathsForVisibleItems)
//        self.totalListCollectionView.reconfigureItems(at: self.totalListCollectionView.indexPathsForVisibleItems)
        
    }
    
    
//    @objc private func memoRecoveredToUncategorized(_ notification: Notification) {
//        print("TotalListVC에서 notification 받음")
//        self.updateSearchResult()
//        var indexPathsToInsert: [IndexPath] = []
//        
//        
//        guard let recoveredMemos = notification.userInfo?["recoveredMemos"] as? [MemoEntity] else { fatalError() }
//        recoveredMemos.forEach { recoveredMemoEntity in
//            if let indexToInsert = self.memoEntitySearhResult.firstIndex(where: { $0 == recoveredMemoEntity }) {
//                indexPathsToInsert.append(IndexPath(item: indexToInsert, section: 0))
//            }
//        }
//        
//        self.totalListCollectionView.insertItems(at: indexPathsToInsert)
//    }
    
    
    private func updateSearchResult() {
        guard let searchController = self.navigationItem.searchController else { fatalError() }
        guard let searchText = searchController.searchBar.searchTextField.text else { fatalError() }
        self.memoEntitySearhResult = MemoEntityManager.shared.searchMemoEntity(with: searchText)
    }
    
    
}



extension TotalListViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.memoEntitySearhResult.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TotalListCollectionViewCell.cellID, for: indexPath) as? TotalListCollectionViewCell else { fatalError() }
        cell.configureCell(with: self.memoEntitySearhResult[indexPath.item])
        return cell
    }
    
}



extension TotalListViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        guard let searchController = self.navigationItem.searchController else { fatalError() }
//        if searchController.isActive {
//            self.navigationItem.searchController?.searchBar.endEditing(true)
//        }
    }
}



//extension TotalListViewController: UIViewControllerTransitioningDelegate {
//    
//    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
//        
//        if source == self.tabBarController {
//            return PopupCardPresentationController(presentedViewController: presented, presenting: presenting, blurBrightness: UIBlurEffect.Style.extraLight)
//        } else {
//            return nil
//        }
//    }
//    
//    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        
//        if source == self.tabBarController {
//            return TotalListViewPopupCardAnimatedTransitioning(animationType: AnimationType.present)
//        } else {
//            return nil
//        }
//    }
//    
//    
//    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        
//        if let popupCardVC = dismissed as? PopupCardViewController {
//            return TotalListViewPopupCardAnimatedTransitioning(animationType: AnimationType.dismiss, interactiveTransition: popupCardVC.percentDrivenInteractiveTransition)
//        } else {
//            return nil
//        }
//        
//    }
//    
//    
////    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
////        
////        guard let popupCardAnimatedTransitioning = animator as? TotalListViewPopupCardAnimatedTransitioning,
////              let percentDrivenInteractiveTransitioning = popupCardAnimatedTransitioning.interactiveTransition,
////                percentDrivenInteractiveTransitioning.interactionInProgress
////        else { return nil }
////        return percentDrivenInteractiveTransitioning
////        
////    }
//    
//}



extension TotalListViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
//        self.shiftUpExtendedBar()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else { fatalError() }
        
        self.updateSearchResult()
        self.totalListCollectionView.reloadData()
        if self.totalListCollectionView.numberOfItems(inSection: 0) > 0 {
            self.totalListCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: UICollectionView.ScrollPosition.bottom, animated: false)
        }
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText == "" {
            self.memoEntitySearhResult = []
            self.totalListCollectionView.reloadData()
            self.totalListCollectionView.showImage()
        } else {
            self.updateSearchResult()
            self.totalListCollectionView.reloadData()
            self.totalListCollectionView.setContentOffset(CGPoint(x: 0, y: -self.view.safeAreaInsets.top), animated: false)
            if self.totalListCollectionView.numberOfItems(inSection: 0) == 0 {
                self.totalListCollectionView.showImage()
            } else {
                self.totalListCollectionView.hideImage()
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print(#function)
        
        self.memoEntitySearhResult = []
        self.totalListCollectionView.reloadData()
        
        if self.totalListCollectionView.numberOfItems(inSection: 0) == 0 {
            self.totalListCollectionView.showImage()
        } else {
            self.totalListCollectionView.hideImage()
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        print(#function)
        
        let collectionViewAlphaAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
        collectionViewAlphaAnimator.addAnimations { [weak self] in
            guard let self else { fatalError() }
            
            if self.totalListCollectionView.traitCollection.userInterfaceStyle == .dark {
                self.totalListCollectionView.alpha = 0.8
            } else {
                self.totalListCollectionView.alpha = 0.5
            }
        }
        collectionViewAlphaAnimator.addCompletion { animatingPosition in
        }
        collectionViewAlphaAnimator.startAnimation()
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        print(#function)
        let collectionViewAlphaAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1)
        collectionViewAlphaAnimator.addAnimations { [weak self] in
            guard let self else { fatalError() }
            self.totalListCollectionView.alpha = 1
        }
        collectionViewAlphaAnimator.startAnimation()
        
        if self.totalListCollectionView.numberOfItems(inSection: 0) == 0 {
            self.totalListCollectionView.showImage()
        } else {
            self.totalListCollectionView.hideImage()
        }
        
        
        return true
    }
    
}

