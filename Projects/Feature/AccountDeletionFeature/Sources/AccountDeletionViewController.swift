//
//  AccountDeletionViewController.swift
//  NoteCard
//

import Shared
import SyncInterface
import UIKit

/// 계정 삭제 흐름을 담당하는 진입 VC.
///
/// 호출 측 (예: 계정 상세 화면) 은 본 VC 를 present 하기만 하면 됨:
/// - 확인 alert 표시 → 사용자가 진행하면 `AccountDeletionService` 호출
/// - 진행 단계 표시는 window 레벨 BlockingProgressOverlay 가 담당 (SceneDelegate 가 service.phasePublisher 구독)
/// - 성공 시 dismiss (이후 `authStatePublisher` 가 nil emit → 호출 측 UI 자동 전환)
/// - 실패 시 사용자 친화적 메시지로 alert + 재시도 가능 상태 유지
public final class AccountDeletionViewController: UIViewController {

    private let accountDeletionService: AccountDeletionService

    private let dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    public init(accountDeletionService: AccountDeletionService) {
        self.accountDeletionService = accountDeletionService
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupLayout()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentConfirmation()
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(dimmingView)
        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    // MARK: - Flow

    private func presentConfirmation() {
        let alert = UIAlertController(
            title: L10n.Account.deleteAccountConfirmTitle,
            message: L10n.Account.deleteAccountConfirmMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.cancel, style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        alert.addAction(UIAlertAction(title: L10n.Account.deleteAccountProceed, style: .destructive) { [weak self] _ in
            self?.startDeletion()
        })
        present(alert, animated: true)
    }

    private func startDeletion() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.accountDeletionService.deleteAccountAndAllData()
                await MainActor.run { self.dismiss(animated: true) }
            } catch AuthError.cancelled {
                // reauth 단계에서 사용자가 Apple 시트 취소 — 흐름 종료, alert 없이 dismiss.
                await MainActor.run { self.dismiss(animated: true) }
            } catch let error as AuthError {
                await MainActor.run {
                    self.presentError(message: error.errorDescription ?? L10n.Sync.Auth.unknown)
                }
            } catch {
                await MainActor.run {
                    self.presentError(message: L10n.Sync.AccountDeletion.dataCleanupFailed)
                }
            }
        }
    }

    private func presentError(message: String) {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}
