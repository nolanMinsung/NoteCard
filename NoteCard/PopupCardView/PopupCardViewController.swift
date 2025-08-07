//
//  PopupCardViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class PopupCardViewController: UIViewController {
    
    lazy var popupCardView = self.view as! PopupCardView
    lazy var selectedImageCollectionView = self.popupCardView.imageCollectionView
    lazy var memoTextView = popupCardView.memoTextView
    
    let selectedCollectionViewCell: UICollectionViewCell
    var selectedIndexPath: IndexPath
    var selectedCellFrame: CGRect
    let cornerRadius: CGFloat
    let isInteractive: Bool
    let memoEntity: MemoEntity
    var isMemoDeleted: Bool = false
    
    lazy var restoreMemoAction = UIAction(
        title: "카테고리 없는 메모로 복구".localized(),
        image: UIImage(systemName: "arrow.counterclockwise")?.withTintColor(.currentTheme, renderingMode: UIImage.RenderingMode.alwaysOriginal),
        handler: { [weak self, weak memoEntity] action in
            guard let self else { fatalError() }
            guard let memoEntity else { fatalError() }
            
            self.popupCardView.endEditing(true)
            
            let alertCon = UIAlertController(title: "이 메모를 복구하시겠습니까?".localized(), message: "복구된 메모는 '카테고리 없음' 항목에서 확인할 수 있습니다.".localized(), preferredStyle: UIAlertController.Style.alert)
            let cancelAction = UIAlertAction(title: "취소".localized(), style: UIAlertAction.Style.cancel)
            let restoreAction = UIAlertAction(title: "복구".localized(), style: UIAlertAction.Style.default) { action in
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
            
            self.popupCardView.endEditing(true)
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
            
            self.popupCardView.endEditing(true)
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
    
    init(memo memoEntity: MemoEntity, selectedCollectionViewCell: UICollectionViewCell, indexPath: IndexPath, selectedCellFrame: CGRect, cornerRadius: CGFloat, isInteractive: Bool) {
        self.memoEntity = memoEntity
        self.selectedCollectionViewCell = selectedCollectionViewCell
        self.selectedIndexPath = indexPath
        self.selectedCellFrame = selectedCellFrame
        self.cornerRadius = cornerRadius
        self.isInteractive = isInteractive
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func loadView() {
        self.view = PopupCardView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupObserver()
        setupDelegates()
        self.popupCardView.configureView(with: self.memoEntity)
        
        if self.memoEntity.isInTrash {
            self.popupCardView.ellipsisButton.menu = UIMenu(children: [self.restoreMemoAction, self.deleteMemoAction])
        } else {
            self.popupCardView.ellipsisButton.menu = UIMenu(children: [self.presentEditingModeAction, self.deleteMemoAction])
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print(String(describing: self), #function)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print(#function)
        super.viewWillDisappear(animated)
        if self.popupCardView.isTextViewChanged {
            self.popupCardView.updateMemoTextView()
        }
    }
    
    private func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(memoRecoveredToUncategorized), name: NSNotification.Name("memoRecoveredToUncategorizedNotification"), object: nil)
    }
    
    @objc private func memoRecoveredToUncategorized() {
        self.dismiss(animated: true)
    }
    
    private func setupDelegates() {
        self.popupCardView.delegate = self
        self.selectedImageCollectionView.delegate = self
    }
    
}


extension PopupCardViewController: LargeCardCollectionViewCellDelegate {
    
    func triggerPresentMethod(selectedItemAt indexPath: IndexPath, imageEntitiesArray: [ImageEntity]) {
        
    }
    
    func triggerPresentMethod(presented presentedVC: UIViewController, animated: Bool) {
        self.present(presentedVC, animated: true)
    }
    
    func triggerApplyingSnapshot(animatingDifferences: Bool, usingReloadData: Bool, completionForCompositional: (() -> Void)?, completionForFlow: (() -> Void)?) {
        return
    }
    
    func updateDataSource() {
        return
    }
    
}


extension PopupCardViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.view.endEditing(true)
        let cardImageShowingVC = CardImageShowingViewController(indexPath: indexPath, imageEntitiesArray: self.popupCardView.sortedImageEntitiesArray)
        cardImageShowingVC.transitioningDelegate = self
        cardImageShowingVC.modalPresentationStyle = .custom
        
        self.present(cardImageShowingVC, animated: true)
    }
    
}


extension PopupCardViewController: UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CardImageShowingPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
}
