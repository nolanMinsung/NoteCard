//
//  PopupCardPresentationController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class PopupCardPresentationController: UIPresentationController {
    
    let blurView: UIVisualEffectView = {
        let view = UIVisualEffectView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapDismiss))
    
    
    override var shouldRemovePresentersView: Bool {
        return false
    }
    
    var blurBrightness: UIBlurEffect.Style?
    
    /// PopupCardPresentationController의 생성자
    /// - Parameters:
    ///   - presentedViewController: presentedViewController 넣기
    ///   - presenting: presentingViewController 넣기
    ///   - blurBrightness: PopupCard를 present할 때 배경의 블러 밝기를 설정. dark, light, extraLight가 있으며, 기본값은 extraLight
    init(presentedViewController: UIViewController, presenting: UIViewController?, blurBrightness: UIBlurEffect.Style) {
        super.init(presentedViewController: presentedViewController, presenting: presenting)
        self.blurBrightness = blurBrightness
    }
    
    
    
    override func presentationTransitionWillBegin() {
        
        guard let containerView else { return }
        containerView.addSubview(self.blurView)
        containerView.addGestureRecognizer(self.tapGesture)
        containerView.isUserInteractionEnabled = true
        self.tapGesture.delegate = self
        
        self.blurView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0).isActive = true
        self.blurView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0).isActive = true
        self.blurView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0).isActive = true
        self.blurView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0).isActive = true
        
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] context in
            guard let self else { return }
            containerView.backgroundColor = UIColor.systemGray5
            self.blurView.effect = UIBlurEffect(style: UIBlurEffect.Style.systemUltraThinMaterial)
//            self.blurView.effect = UIBlurEffect(style: UIBlurEffect.Style.systemThickMaterial)
//            self.blurView.effect = UIBlurEffect(style: UIBlurEffect.Style.dark)
            
        })
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        
    }
    
    override func dismissalTransitionWillBegin() {
        guard let containerView else { return }
        guard let popupCardView = self.presentedView as? PopupCardView else { fatalError() }
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] context in
            guard let self else { return }
            self.blurView.effect = .none
            containerView.backgroundColor = .clear
            popupCardView.memoDateLabel.isHidden = true
        })
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        switch completed {
        case true:
            self.containerView?.removeGestureRecognizer(self.tapGesture)
            self.blurView.removeFromSuperview()
            guard let popupCardVC = presentedViewController as? PopupCardViewController else { return }
            
            if let tabBarCon = presentingViewController as? UITabBarController {
                guard let naviCon = tabBarCon.selectedViewController as? UINavigationController else { return }
                if let totalListVC = naviCon.topViewController as? TotalListViewController {
                    
                } else if let memoVC = naviCon.topViewController as? MemoViewController {
                    if popupCardVC.memoEntity.isInTrash {
                        
                        //totalListVC에서는 메모가 지워졌을 때 reloadData하지 않는 이유가, totalListVC의 경우에는 셀을 선택할 때 당시의 indexPath를 기준으로 돌아갈 셀을 참조한다.
                        
                        /*
                        memoVC.applySnapshot(animatingDifferences: true, usingReloadData: false, completionForFlow: { [weak memoVC] in
                            guard let memoVC else { fatalError() }
                            print("memoVC의 memoEntitiesArray 의 count는?", memoVC.memoEntitiesArray.count)
                            if memoVC.memoEntitiesArray.count == 0 {
                                memoVC.setEditing(false, animated: false)
                                memoVC.editButtonItem.isEnabled = false
                            } else {
                                memoVC.editButtonItem.isEnabled = true
                            }
                        })
                         */
                    }
                    
                } else if let homeVC = naviCon.topViewController as? HomeViewController {
                    let homeCollectionView = homeVC.homeCollectionView
                    homeCollectionView.reloadData()
                }
                
            }
            
            
        case false:
            return
        }
        
    }
    
    @objc private func tapDismiss() {
        
        
//        guard let popupCardVC = presentedViewController as? PopupCardViewController else { fatalError() }
        guard let popupCardView = presentedView as? PopupCardView else { fatalError() }
//        if popupCardView.titleTextField.isFirstResponder || popupCardView.memoTextView.isFirstResponder {
        if popupCardView.titleTextField.isFirstResponder || popupCardView.memoTextView.isFirstResponder {
            return
        } else {
            presentedViewController.dismiss(animated: true)
        }
    }
    
}


extension PopupCardPresentationController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == self.tapGesture {
            guard let touchedView = touch.view else { return false }
            guard let presentedView else { return false }
            guard !touchedView.isDescendant(of: presentedView) else { return false }
            return true
        } else {
            return true
        }
    }
    
}

