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
/// - 진행 중 ActivityIndicator 표시
/// - 성공 시 dismiss (이후 `authStatePublisher` 가 nil emit → 호출 측 UI 자동 전환)
/// - 실패 시 사용자 친화적 메시지로 alert + 재시도 가능 상태 유지
///
/// 추후 폴리시 여지: 진행률 화면, 데이터 항목 별 진행 단계, reauth 안내 화면 등을 본 VC 안에서 확장.
public final class AccountDeletionViewController: UIViewController {

    private let accountDeletionService: AccountDeletionService

    private let dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let progressLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.Sync.AccountDeletion.inProgress
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .body)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
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
        view.addSubview(activityIndicator)
        view.addSubview(progressLabel)

        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            progressLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            progressLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            progressLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
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
        setProgress(true)
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
                    self.setProgress(false)
                    self.presentError(message: error.errorDescription ?? L10n.Sync.Auth.unknown)
                }
            } catch {
                await MainActor.run {
                    self.setProgress(false)
                    self.presentError(message: L10n.Sync.AccountDeletion.dataCleanupFailed)
                }
            }
        }
    }

    private func setProgress(_ active: Bool) {
        if active {
            activityIndicator.startAnimating()
            progressLabel.isHidden = false
        } else {
            activityIndicator.stopAnimating()
            progressLabel.isHidden = true
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
