//
//  PopupCardViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class PopupCardViewController: UIViewController {
    
    lazy var rootView = PopupCardView()
    lazy var selectedImageCollectionView = self.rootView.imageCollectionView
    lazy var memoTextView = rootView.memoTextView
    let memoTextViewTapGesture = UITapGestureRecognizer()
    
    let memoEntity: MemoEntity
    var isMemoDeleted: Bool = false
    
    lazy var restoreMemoAction = UIAction(
        title: "카테고리 없는 메모로 복구".localized(),
        image: UIImage(systemName: "arrow.counterclockwise")?.withTintColor(.currentTheme, renderingMode: UIImage.RenderingMode.alwaysOriginal),
        handler: { [weak self] action in
            guard let self else { fatalError() }
            
            self.rootView.endEditing(true)
            
            let alertCon = UIAlertController(
                title: "이 메모를 복구하시겠습니까?".localized(),
                message: "복구된 메모는 '카테고리 없음' 항목에서 확인할 수 있습니다.".localized(),
                preferredStyle: UIAlertController.Style.alert
            )
            let cancelAction = UIAlertAction(title: "취소".localized(), style: .cancel)
            let restoreAction = UIAlertAction(title: "복구".localized(), style: .default) { action in
                self.restore(memoEntity: self.memoEntity)
                self.dismiss(animated: true)
            }
            alertCon.addAction(cancelAction)
            alertCon.addAction(restoreAction)
            
            self.present(alertCon, animated: true)
        }
    )
    
    lazy var presentEditingModeAction = UIAction(
        title: "편집 모드".localized(),
        image: UIImage(systemName: "pencil"),
        handler: { [weak self] action in
            guard let self else { return }
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
            
            self.rootView.endEditing(true)
            let memoEditingVC = MemoEditingViewController(memo: self.memoEntity)
            appDelegate.memoEditingVC = memoEditingVC
            let memoEditingNaviCon = UINavigationController(rootViewController: memoEditingVC)
            self.present(memoEditingNaviCon, animated: true)
        }
    )
    
    lazy var deleteMemoAction = UIAction(
        title: "이 메모 삭제하기".localized(),
        image: UIImage(systemName: "trash"),
        attributes: UIMenuElement.Attributes.destructive,
        handler: { [weak self] action in
            guard let self else { return }
            
            self.rootView.endEditing(true)
            let alertCon: UIAlertController
            if self.memoEntity.isInTrash {
                alertCon = UIAlertController(
                    title: "선택한 메모를 영구적으로 삭제하시겠습니까?".localized(),
                    message: "이 동작은 취소할 수 없습니다.".localized(),
                    preferredStyle: UIAlertController.Style.actionSheet
                )
            } else {
                alertCon = UIAlertController(title: "메모 삭제".localized(), message: "메모를 삭제하시겠습니까?".localized(), preferredStyle: UIAlertController.Style.alert)
            }
            alertCon.view.tintColor = .currentTheme
            
            let cancelAction = UIAlertAction(title: "취소".localized(), style: .cancel)
            let deleteAction = UIAlertAction(title: "삭제".localized(), style: .destructive) { [weak memoEntity] action in
                guard let memoEntity else { fatalError() }
                
                if memoEntity.isInTrash {
                    MemoEntityManager.shared.deleteMemoEntity(memoEntity: memoEntity)
                    
                } else {
                    MemoEntityManager.shared.trashMemo(memoEntity)
                    
                    NotificationCenter.default.post(name: NSNotification.Name("memoTrashedNotification"), object: nil, userInfo: ["trashedMemos": [memoEntity]])
                }
                
                guard let presentingTabBarCon = self.presentingViewController as? UITabBarController else { fatalError() }
                guard let selectedNaviCon = presentingTabBarCon.selectedViewController as? UINavigationController else { fatalError() }
                if let memoVC = selectedNaviCon.topViewController as? MemoViewController {
                    guard let indexToTrash = memoVC.memoEntitiesArray.firstIndex(of: memoEntity) else { fatalError() }
                    let indexPathToTrash = IndexPath(item: indexToTrash, section: 0)
                    
                    memoVC.updateDataSource()
                    memoVC.smallCardCollectionView.deleteItems(at: [indexPathToTrash])
                }
                
                self.dismiss(animated: true)
                
                
            }
            alertCon.addAction(cancelAction)
            alertCon.addAction(deleteAction)
            
            self.present(alertCon, animated: true)
        }
    )
    
    init(memo memoEntity: MemoEntity, indexPath: IndexPath, enableEditing: Bool = true) {
        self.memoEntity = memoEntity
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
        self.rootView.configureView(with: self.memoEntity)
        
        if self.memoEntity.isInTrash {
            self.rootView.ellipsisButton.menu = UIMenu(children: [self.restoreMemoAction, self.deleteMemoAction])
        } else {
            self.rootView.ellipsisButton.menu = UIMenu(children: [self.presentEditingModeAction, self.deleteMemoAction])
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
//        rootView.memoTextView.isSelectable = true
        memoTextViewTapGesture.isEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.rootView.isTextViewChanged {
            self.rootView.updateMemoTextView()
        }
    }
    
    private func setupDelegates() {
        self.selectedImageCollectionView?.delegate = self
    }
    
}


private extension PopupCardViewController {
    
    @objc func likeButtonTapped() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
        rootView.likeButton.isSelected.toggle()
        appDelegate.saveContext()
        memoEntity.isFavorite = rootView.likeButton.isSelected
    }
    
}


// MARK: - UICollectionViewDelegate
extension PopupCardViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.view.endEditing(true)
        let cardImageShowingVC = CardImageShowingViewController(indexPath: indexPath, imageEntitiesArray: self.rootView.sortedImageEntitiesArray)
        cardImageShowingVC.transitioningDelegate = self
        cardImageShowingVC.modalPresentationStyle = .custom
        
        self.present(cardImageShowingVC, animated: true)
    }
    
}


// MARK: - UIViewControllerTransitioningDelegate
extension PopupCardViewController: UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CardImageShowingPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
}


// MARK: - Managing MemoEntity
private extension PopupCardViewController {
    
    func restore(memoEntity: MemoEntity) {
        MemoEntityManager.shared.restoreMemo(memoEntity)
        
        guard let presentingTabBarCon = self.presentingViewController as? UITabBarController else { fatalError() }
        guard let selectedNaviCon = presentingTabBarCon.selectedViewController as? UINavigationController else { fatalError() }
        guard let memoVC = selectedNaviCon.topViewController as? MemoViewController else { fatalError() }
        guard memoVC.memoVCType == .trash else { return }
        guard let indexToRestore = memoVC.memoEntitiesArray.firstIndex(of: memoEntity) else { fatalError() }
        let indexPathToRestore = IndexPath(item: indexToRestore, section: 0)
        memoVC.updateDataSource()
        memoVC.smallCardCollectionView.deleteItems(at: [indexPathToRestore])
        
        NotificationCenter.default.post(name: NSNotification.Name("memoRecoveredToUncategorizedNotification"), object: nil, userInfo: ["recoveredMemos": [memoEntity]])
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
