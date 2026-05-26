//
//  SyncIntroductionViewController.swift
//  NoteCard
//

import UIKit

/// 기존 사용자에게 동기화 기능이 추가됐음을 안내하는 sheet 모달.
///
/// 직접 로그인 버튼은 노출하지 않고 Settings 진입을 자연스럽게 유도하는 톤.
/// 호출자가 `UISheetPresentationController.detents = [.medium()]`로 띄운다고 가정.
final class SyncIntroductionViewController: UIViewController {

    private lazy var rootView = self.view as! SyncIntroductionView

    override func loadView() {
        self.view = SyncIntroductionView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        rootView.dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
    }

    @objc private func dismissTapped() {
        dismiss(animated: true)
    }
}
