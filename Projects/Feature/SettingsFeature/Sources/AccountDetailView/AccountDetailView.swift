//
//  AccountDetailView.swift
//  NoteCard
//

import AuthenticationServices
import Shared
import UIKit

final class AccountDetailView: UIView {

    // MARK: - Signed-out state

    let signedOutContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    let signInPromptLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.Account.signInPrompt
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    let signInButton: ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: .black)
        button.cornerRadius = 12
        return button
    }()

    // MARK: - Signed-in state

    let signedInContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    let displayNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    let emailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    let syncStatusRow = AccountDetailView.makeInfoRow(title: L10n.Account.syncStatusLabel, value: L10n.Account.syncStatusComingSoon)
    let lastSyncedRow = AccountDetailView.makeInfoRow(title: L10n.Account.lastSyncedLabel, value: L10n.Account.lastSyncedNever)

    let signOutButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = L10n.Account.signOut
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 0, bottom: 14, trailing: 0)
        let button = UIButton(configuration: config)
        return button
    }()

    let deleteAccountButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = L10n.Account.deleteAccount
        var attrs = AttributeContainer()
        attrs.font = .systemFont(ofSize: 14)
        attrs.foregroundColor = .systemRed
        config.attributedTitle = AttributedString(L10n.Account.deleteAccount, attributes: attrs)
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
        let button = UIButton(configuration: config)
        return button
    }()

    let activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .systemGroupedBackground

        let identityStack = UIStackView(arrangedSubviews: [displayNameLabel, emailLabel])
        identityStack.axis = .vertical
        identityStack.spacing = 4
        identityStack.alignment = .center

        let infoStack = UIStackView(arrangedSubviews: [syncStatusRow, lastSyncedRow])
        infoStack.axis = .vertical
        infoStack.spacing = 8
        infoStack.alignment = .fill

        signedInContainer.addArrangedSubview(identityStack)
        signedInContainer.addArrangedSubview(infoStack)
        signedInContainer.setCustomSpacing(28, after: identityStack)
        signedInContainer.addArrangedSubview(signOutButton)
        signedInContainer.setCustomSpacing(32, after: infoStack)
        signedInContainer.addArrangedSubview(deleteAccountButton)

        signedOutContainer.addArrangedSubview(signInPromptLabel)
        signedOutContainer.addArrangedSubview(signInButton)

        addSubview(signedOutContainer)
        addSubview(signedInContainer)
        addSubview(activityIndicator)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            signedOutContainer.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 24),
            signedOutContainer.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -24),
            signedOutContainer.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 40),

            signInButton.heightAnchor.constraint(equalToConstant: 50),

            signedInContainer.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 24),
            signedInContainer.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -24),
            signedInContainer.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 40),

            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    // MARK: - Helpers

    /// 라벨-값 한 줄을 만드는 단순 행. systemGroupedBackground 위 흰 카드 느낌.
    private static func makeInfoRow(title: String, value: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 10
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 15)
        valueLabel.textColor = .secondaryLabel
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.tag = AccountDetailView.valueLabelTag

        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12),
        ])
        return container
    }

    /// row 안의 valueLabel을 찾기 위한 식별 tag. row 갱신 헬퍼에서 사용.
    fileprivate static let valueLabelTag = 5001
}

extension AccountDetailView {
    /// 행 내부의 값 라벨 텍스트를 갱신.
    func updateRow(_ row: UIView, value: String) {
        guard let label = row.viewWithTag(Self.valueLabelTag) as? UILabel else { return }
        label.text = value
    }
}
