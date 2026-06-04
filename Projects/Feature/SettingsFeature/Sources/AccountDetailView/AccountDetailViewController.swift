//
//  AccountDetailViewController.swift
//  NoteCard
//

import AccountDeletionFeature
import AuthenticationServices
import Combine
import Shared
import SyncInterface
import UIKit

/// Settings → 계정에서 진입하는 상세 페이지.
/// 미로그인이면 Sign in with Apple 버튼, 로그인 상태면 사용자 정보 + 로그아웃/계정 삭제.
public final class AccountDetailViewController: UIViewController {

    private let authService: AuthService
    private let accountDeletionService: AccountDeletionService
    private let syncStatusService: SyncStatusService
    private let readinessCoordinator: FirstSignInReadinessCoordinator
    private let readinessTimeout: TimeInterval
    private var cancellables = Set<AnyCancellable>()
    private var lastSyncedAt: Date?
    private var lastSyncedRefreshTimer: Timer?

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    private lazy var rootView = self.view as! AccountDetailView

    public init(
        authService: AuthService,
        accountDeletionService: AccountDeletionService,
        syncStatusService: SyncStatusService,
        readinessCoordinator: FirstSignInReadinessCoordinator,
        readinessTimeout: TimeInterval = 90
    ) {
        self.authService = authService
        self.accountDeletionService = accountDeletionService
        self.syncStatusService = syncStatusService
        self.readinessCoordinator = readinessCoordinator
        self.readinessTimeout = readinessTimeout
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        lastSyncedRefreshTimer?.invalidate()
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

        attachSignInButtonTarget(rootView.signInButton)
        rootView.onSignInButtonRecreated = { [weak self] button in
            // 다크모드 토글로 인스턴스가 교체되면 새 인스턴스에 action 재부착.
            self?.attachSignInButtonTarget(button)
        }
        rootView.signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
        rootView.deleteAccountButton.addTarget(self, action: #selector(deleteAccountTapped), for: .touchUpInside)
        rootView.syncRetryButton.addTarget(self, action: #selector(syncRetryTapped), for: .touchUpInside)

        // 인증 상태 변경에 따라 화면 상태 토글.
        authService.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.render(user: user)
            }
            .store(in: &cancellables)

        // 동기화 상태 / 최근 동기화 라벨 binding.
        syncStatusService.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.renderSyncStatus(status)
            }
            .store(in: &cancellables)

        syncStatusService.lastSyncedAtPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] date in
                self?.lastSyncedAt = date
                self?.renderLastSyncedRelativeText()
            }
            .store(in: &cancellables)

        // RelativeDateTimeFormatter 결과 ("방금 전" → "1분 전" → ...) 를 시간이 흐름에 따라 갱신.
        // viewWillAppear / viewWillDisappear 와 별개로 30초 tick. 화면이 가려져 있어도 무해.
        lastSyncedRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.renderLastSyncedRelativeText()
        }
    }

    // MARK: - State render

    private func renderSyncStatus(_ status: SyncStatus) {
        let text: String
        switch status {
        case .unknown: text = L10n.Account.syncStatusUnknown
        case .syncing: text = L10n.Account.syncStatusSyncing
        case .synced:  text = L10n.Account.syncStatusSynced
        }
        rootView.updateRow(rootView.syncStatusRow, value: text)
    }

    private func renderLastSyncedRelativeText() {
        let text: String
        if let date = lastSyncedAt {
            text = Self.relativeFormatter.localizedString(for: date, relativeTo: Date())
        } else {
            text = L10n.Account.lastSyncedNever
        }
        rootView.updateRow(rootView.lastSyncedRow, value: text)
    }

    private func render(user: AuthUser?) {
        if let user {
            rootView.signedOutContainer.isHidden = true
            rootView.signedInContainer.isHidden = false
            rootView.displayNameLabel.text = user.displayName ?? user.email ?? L10n.Account.title
            rootView.emailLabel.text = user.email
            rootView.emailLabel.isHidden = (user.email == nil)
            updateSyncRetryVisibility(userID: user.id)
        } else {
            rootView.signedOutContainer.isHidden = false
            rootView.signedInContainer.isHidden = true
            rootView.syncRetryContainer.isHidden = true
        }
    }

    private func updateSyncRetryVisibility(userID: String) {
        let incomplete = !readinessCoordinator.isSyncCompleted(for: userID)
        rootView.syncRetryContainer.isHidden = !incomplete
    }

    // MARK: - Actions

    private func attachSignInButtonTarget(_ button: ASAuthorizationAppleIDButton) {
        button.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
    }

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

    @objc private func syncRetryTapped() {
        guard let userID = authService.currentUser?.id else { return }
        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            defer { Task { @MainActor in self.setLoading(false) } }
            do {
                try await self.readinessCoordinator.retryReady(userID: userID, timeout: self.readinessTimeout)
                await MainActor.run {
                    self.rootView.syncRetryContainer.isHidden = true
                    self.showAlert(title: L10n.Account.syncRetrySuccessMessage)
                }
            } catch is SignInReadinessError {
                await MainActor.run { self.showAlert(title: L10n.Login.syncTimeoutError) }
            } catch {
                await MainActor.run { self.showAlert(title: L10n.Sync.Auth.unknown) }
            }
        }
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
        rootView.syncRetryButton.isEnabled = !loading
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
