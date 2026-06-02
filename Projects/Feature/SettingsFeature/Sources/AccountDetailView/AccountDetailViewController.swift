//
//  AccountDetailViewController.swift
//  NoteCard
//

import AccountDeletionFeature
import Combine
import Shared
import SyncInterface
import UIKit

/// Settings → 계정에서 진입하는 상세 페이지.
/// 미로그인이면 Sign in with Apple 버튼, 로그인 상태면 사용자 정보 + 로그아웃/계정 삭제.
public final class AccountDetailViewController: UIViewController {

    private let authService: AuthService
    private let accountDeletionService: AccountDeletionService
    private var cancellable: AnyCancellable?

    private lazy var rootView = self.view as! AccountDetailView

    public init(authService: AuthService, accountDeletionService: AccountDeletionService) {
        self.authService = authService
        self.accountDeletionService = accountDeletionService
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    public override func loadView() {
        self.view = AccountDetailView()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.Account.title
        navigationItem.largeTitleDisplayMode = .never

        rootView.signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
        rootView.signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
        rootView.deleteAccountButton.addTarget(self, action: #selector(deleteAccountTapped), for: .touchUpInside)

        // 인증 상태 변경에 따라 화면 상태 토글.
        cancellable = authService.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.render(user: user)
            }
    }

    // MARK: - State render

    private func render(user: AuthUser?) {
        if let user {
            rootView.signedOutContainer.isHidden = true
            rootView.signedInContainer.isHidden = false
            rootView.displayNameLabel.text = user.displayName ?? user.email ?? L10n.Account.title
            rootView.emailLabel.text = user.email
            rootView.emailLabel.isHidden = (user.email == nil)
        } else {
            rootView.signedOutContainer.isHidden = false
            rootView.signedInContainer.isHidden = true
        }
    }

    // MARK: - Actions

    @objc private func signInTapped() {
        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            defer { Task { @MainActor in self.setLoading(false) } }
            do {
                _ = try await self.authService.signInWithApple()
                // 성공 시 authStatePublisher가 새 user를 emit → render에서 자동 전환
            } catch let error as AuthError {
                await MainActor.run { self.presentInline(error: error) }
            } catch {
                await MainActor.run { self.showAlert(title: L10n.Sync.Auth.unknown) }
            }
        }
    }

    @objc private func signOutTapped() {
        let alert = UIAlertController(
            title: L10n.Account.signOutConfirmTitle,
            message: L10n.Account.signOutConfirmMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.Account.signOut, style: .destructive) { [weak self] _ in
            self?.performSignOut()
        })
        present(alert, animated: true)
    }

    @objc private func deleteAccountTapped() {
        let deletionVC = AccountDeletionViewController(accountDeletionService: accountDeletionService)
        present(deletionVC, animated: true)
    }

    private func performSignOut() {
        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            defer { Task { @MainActor in self.setLoading(false) } }
            do {
                try await self.authService.signOut()
                // authStatePublisher가 nil emit → 미로그인 상태로 자동 전환
            } catch {
                await MainActor.run { self.showAlert(title: L10n.Sync.Auth.unknown) }
            }
        }
    }

    // MARK: - Helpers

    private func setLoading(_ loading: Bool) {
        rootView.signInButton.isEnabled = !loading
        rootView.signOutButton.isEnabled = !loading
        rootView.deleteAccountButton.isEnabled = !loading
        if loading { rootView.activityIndicator.startAnimating() } else { rootView.activityIndicator.stopAnimating() }
    }

    private func presentInline(error: AuthError) {
        switch error {
        case .cancelled:
            return
        case .missingFirebase:
            showAlert(title: L10n.Sync.Auth.unavailable)
        case .invalidCredential:
            showAlert(title: L10n.Sync.Auth.invalidCredential)
        case .requiresRecentLogin:
            // 로그인 진입점에선 발생하지 않는 케이스 (delete 흐름 전용). 방어적으로 unknown 메시지.
            showAlert(title: L10n.Sync.Auth.unknown)
        case .unknown:
            showAlert(title: L10n.Sync.Auth.unknown)
        }
    }

    private func showAlert(title: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        present(alert, animated: true)
    }
}
