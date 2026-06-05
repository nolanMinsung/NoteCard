//
//  LoginView.swift
//  NoteCard
//

import AuthenticationServices
import DesignSystem
import Shared
import UIKit

final class LoginView: UIView {

    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "NoteCard"
        label.font = .systemFont(ofSize: 36, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    let promptLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.Login.promptDescription
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

    let skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(L10n.Login.skipButton, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15)
        return button
    }()

    let errorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .systemRed
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()


    private lazy var topStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, promptLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var buttonStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [signInButton, errorLabel, skipButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
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
        backgroundColor = .loginBackground

        addSubview(topStack)
        addSubview(buttonStack)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            topStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            topStack.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -100),
            topStack.leadingAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.leadingAnchor, constant: 24),
            topStack.trailingAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.trailingAnchor, constant: -24),

            buttonStack.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 24),
            buttonStack.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -24),
            buttonStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -40),

            signInButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}
