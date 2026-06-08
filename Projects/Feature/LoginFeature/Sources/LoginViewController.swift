//
//  LoginViewController.swift
//  NoteCard
//

import AnalyticsInterface
import Combine
import Domain
import Shared
import SyncInterface
import UIKit

/// 신규 사용자가 앱을 처음 켰을 때 표시되는 fullScreen 진입 화면.
///
/// 두 가지 결과를 `onCompletion`으로 알린다:
/// - `.signedIn`: Apple Sign in 성공 → 호출자가 rootVC를 메인 화면으로 교체
/// - `.skipped`: 사용자가 "로그인 없이 사용"을 확정 → 호출자가 rootVC 교체 + 다음 실행 시 재표시 금지 플래그 set
public final class LoginViewController: UIViewController {

    public enum Outcome {
        case signedIn
        case skipped
    }

    private let authService: AuthService
    private let readinessCoordinator: FirstSignInReadinessCoordinator
    private let readinessTimeout: TimeInterval
    private let analytics: Analytics
    private let provideAnonymousCounts: @Sendable () -> AnonymousDataCounts
    private let onCompletion: (Outcome) -> Void

    private var cancellables = Set<AnyCancellable>()

    private lazy var rootView = self.view as! LoginView

    // MARK: - Init

    public init(
        authService: AuthService,
        readinessCoordinator: FirstSignInReadinessCoordinator,
        analytics: Analytics,
        provideAnonymousCounts: @escaping @Sendable () -> AnonymousDataCounts,
        readinessTimeout: TimeInterval = 90,
        onCompletion: @escaping (Outcome) -> Void
    ) {
        self.authService = authService
        self.readinessCoordinator = readinessCoordinator
        self.analytics = analytics
        self.provideAnonymousCounts = provideAnonymousCounts
        self.readinessTimeout = readinessTimeout
        self.onCompletion = onCompletion
        super.init(nibName: nil, bundle: nil)
        // 첫 진입은 swipe-down으로 닫을 수 없게. skip 버튼이 명시적 대안.
        isModalInPresentation = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    // MARK: - Lifecycle

    public override func loadView() {
        self.view = LoginView()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        rootView.signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
        rootView.skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func signInTapped() {
        rootView.errorLabel.text = nil
        setLoading(true)
        readinessCoordinator.reportSigningIn()
        analytics.log(.signInStarted(source: .loginScreen))
        let counts = provideAnonymousCounts()
        analytics.log(.anonymousDataStats(
            memoCount: counts.memoCount,
            trashedMemoCount: counts.trashedMemoCount,
            categoryCount: counts.categoryCount,
            imageCount: counts.imageCount
        ))
        let startedAt = Date()
        Task { [weak self] in
            guard let self else { return }
            let logOutcome: (AnalyticsEvent.SignInOutcome) -> Void = { outcome in
                let durationMs = Int(Date().timeIntervalSince(startedAt) * 1000)
                self.analytics.log(.signInOutcome(source: .loginScreen, outcome: outcome, durationMs: durationMs))
            }
            do {
                let user = try await self.authService.signInWithApple()
                try await self.readinessCoordinator.awaitReady(userID: user.id, timeout: self.readinessTimeout)
                self.analytics.setUserId(user.id)
                logOutcome(.success)
                await MainActor.run {
                    self.setLoading(false)
                    self.onCompletion(.signedIn)
                }
            } catch let error as AuthError {
                let outcome: AnalyticsEvent.SignInOutcome
                if case .cancelled = error { outcome = .cancelled } else { outcome = .authError }
                logOutcome(outcome)
                await MainActor.run {
                    self.setLoading(false)
                    self.present(error: error)
                }
            } catch is SignInReadinessError {
                logOutcome(.readinessTimeout)
                await MainActor.run {
                    self.setLoading(false)
                    self.rootView.errorLabel.text = L10n.Login.syncTimeoutError
                }
            } catch {
                logOutcome(.unknownError)
                await MainActor.run {
                    self.setLoading(false)
                    self.rootView.errorLabel.text = L10n.Sync.Auth.unknown
                }
            }
        }
    }

    @objc private func skipTapped() {
        let alert = UIAlertController(
            title: L10n.Login.skipConfirmationTitle,
            message: L10n.Login.skipConfirmationMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.Login.skipConfirmationProceed, style: .default) { [weak self] _ in
            self?.proceedWithSkip()
        })
        present(alert, animated: true)
    }

    /// readiness gate 가 실패한 뒤 사용자가 skip 을 누른 경우, Firebase 측은 sign-in 된 상태가 잔존.
    /// UI 와 인증 상태를 일치시키기 위해 sign-out 후 .skipped emit.
    private func proceedWithSkip() {
        analytics.log(.signInSkipped())
        if authService.currentUser == nil {
            onCompletion(.skipped)
            return
        }
        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            try? await self.authService.signOut()
            await MainActor.run {
                self.setLoading(false)
                self.onCompletion(.skipped)
            }
        }
    }

    // MARK: - Private

    private func present(error: AuthError) {
        switch error {
        case .cancelled:
            // 사용자가 직접 닫은 액션. 추가 알림 없이 화면에 머무름.
            rootView.errorLabel.text = nil
        case .missingFirebase:
            rootView.errorLabel.text = L10n.Sync.Auth.unavailable
        case .invalidCredential:
            rootView.errorLabel.text = L10n.Sync.Auth.invalidCredential
        case .unknown:
            rootView.errorLabel.text = L10n.Sync.Auth.unknown
        }
    }

    private func setLoading(_ loading: Bool) {
        rootView.signInButton.isEnabled = !loading
        rootView.skipButton.isEnabled = !loading
        if !loading {
            readinessCoordinator.reset()
        }
    }
}
