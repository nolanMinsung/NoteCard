//
//  PopupCardViewController+Trashed.swift
//  NoteCard
//
//  Created by 김민성 on 9/9/25.
//

import UIKit

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
                try await MemoEntityRepository.shared.restore(self.memo)
                self.dismiss(animated: true)
            }
//            self.restore(memoEntity: self.memoEntity)
//            self.dismiss(animated: true)
        }
        alertCon.addAction(cancelAction)
        alertCon.addAction(restoreAction)
        
        self.present(alertCon, animated: true)
    }
    
//    private func restore(memoEntity: MemoEntity) {
//        MemoEntityManager.shared.restoreMemo(memoEntity)
//        
//        guard let presentingTabBarCon = self.presentingViewController as? UITabBarController else { fatalError() }
//        guard let selectedNaviCon = presentingTabBarCon.selectedViewController as? UINavigationController else { fatalError() }
//        guard let memoVC = selectedNaviCon.topViewController as? MemoViewController else { fatalError() }
//        guard memoVC.memoVCType == .trash else { return }
//        guard let indexToRestore = memoVC.memoEntitiesArray.firstIndex(of: memoEntity) else { fatalError() }
//        let indexPathToRestore = IndexPath(item: indexToRestore, section: 0)
//        memoVC.updateDataSource()
//        memoVC.smallCardCollectionView.deleteItems(at: [indexPathToRestore])
//        
//        NotificationCenter.default.post(name: NSNotification.Name("memoRecoveredToUncategorizedNotification"), object: nil, userInfo: ["recoveredMemos": [memoEntity]])
//    }
    
}


extension PopupCardViewController {
    
    func askDeleting() {
        self.rootView.endEditing(true)
        let title = (memo.isInTrash ? "선택한 메모를 영구적으로 삭제하시겠습니까?".localized() : "메모 삭제".localized())
        let message = (memo.isInTrash ? "이 동작은 취소할 수 없습니다.".localized() : "메모를 삭제하시겠습니까?".localized())
        let alertstyle: UIAlertController.Style = memo.isInTrash ? .actionSheet : .alert
        let alertCon = UIAlertController(title: title, message: message, preferredStyle: alertstyle)
        alertCon.view.tintColor = .currentTheme
        
        let cancelAction = UIAlertAction(title: "취소".localized(), style: .cancel)
        let deleteAction = UIAlertAction(title: "삭제".localized(), style: .destructive) { [weak self] action in
            Task {
                guard let self else { return }
                if self.memo.isInTrash {
                    try await MemoEntityRepository.shared.deleteMemo(self.memo)
                } else {
                    try await MemoEntityRepository.shared.moveToTrash(self.memo)
                }
                self.dismiss(animated: true)
            }
        }
        alertCon.addAction(cancelAction)
        alertCon.addAction(deleteAction)
        self.present(alertCon, animated: true)
    }
    
}
