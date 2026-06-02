//
//  LoginViewController.swift
//  NoteCard
//

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
    private let onCompletion: (Outcome) -> Void

    private lazy var rootView = self.view as! LoginView

    // MARK: - Init

    public init(authService: AuthService, onCompletion: @escaping (Outcome) -> Void) {
        self.authService = authService
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
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.authService.signInWithApple()
                await MainActor.run {
                    self.setLoading(false)
                    self.onCompletion(.signedIn)
                }
            } catch let error as AuthError {
                await MainActor.run {
                    self.setLoading(false)
                    self.present(error: error)
                }
            } catch {
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
            self?.onCompletion(.skipped)
        })
        present(alert, animated: true)
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
        if loading {
            rootView.activityIndicator.startAnimating()
        } else {
            rootView.activityIndicator.stopAnimating()
        }
    }
}
