//
//  BlockingProgressOverlay.swift
//  NoteCard
//

import UIKit

/// Window 레벨에서 전체 화면 터치를 가로채고 진행 상황 텍스트를 보여주는 overlay.
/// rootViewController 교체와 무관하게 살아남도록 window 에 직접 add 됨.
/// Sign-in / sign-out / 계정 삭제 같은 비동기 흐름이 끝날 때까지 사용자 인터랙션을 차단.
final class BlockingProgressOverlay: UIView {

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

    private let messageLabel: UILabel = {
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
        addSubview(messageLabel)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -12),

            messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32)
        ])

        activityIndicator.startAnimating()
    }

    func update(text: String?) {
        messageLabel.text = text
    }
}
