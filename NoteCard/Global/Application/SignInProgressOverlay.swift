//
//  SignInProgressOverlay.swift
//  NoteCard
//

import Shared
import SyncInterface
import UIKit

/// Window 레벨에서 전체 화면 터치를 가로채고 현재 sign-in phase 를 안내하는 overlay.
/// rootViewController 교체 (LoginVC → MainTabBar / AccountDetail → MainTabBar) 와 무관하게
/// window 에 직접 add 되어 sign-in 전체 흐름 동안 살아남음.
final class SignInProgressOverlay: UIView {

    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.85)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let phaseLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    private func setupUI() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(backgroundView)
        addSubview(activityIndicator)
        addSubview(phaseLabel)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -12),

            phaseLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            phaseLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            phaseLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32)
        ])

        activityIndicator.startAnimating()
    }

    func update(phase: SignInPhase) {
        let oldText = phaseLabel.text ?? "nil"
        switch phase {
        case .signingIn:
            phaseLabel.text = L10n.Login.phaseSigningIn
        case .uploading:
            phaseLabel.text = L10n.Login.phaseUploading
        case .downloading:
            phaseLabel.text = L10n.Login.phaseDownloading
        case .idle, .ready:
            phaseLabel.text = nil
        }
        print("[DEBUG-Overlay] update label '\(oldText)' → '\(phaseLabel.text ?? "nil")' @ \(String(format: "%.3f", CFAbsoluteTimeGetCurrent()))")
    }
}
