//
//  PopupCardSearchBar.swift
//  NoteCard
//
//  Created by 김민성 on 6/9/26.
//

import UIKit
import DesignSystem
import Shared

/// PopupCard 본문 TextView 와 키보드 사이에 붙는 '메모 내 검색' 바.
/// 검색어 입력 / 결과 카운트 / 이전·다음 이동 / 종료만 담당하는 순수 뷰이며,
/// 실제 검색·하이라이트 로직은 PopupCardViewController 가 클로저로 받아 처리한다.
final class PopupCardSearchBar: UIView {

    let searchTextField = UITextField()

    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let previousButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let countLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let controlStackView = UIStackView()

    var onQueryChanged: ((String) -> Void)?
    var onTapPrevious: (() -> Void)?
    var onTapNext: (() -> Void)?
    var onTapClose: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        setupSearchTextField()
        setupControls()
        configureHierarchy()
        setupConstraints()
        setupActions()

        updateCount(current: 0, total: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 결과 카운트("현재/전체") 갱신. 일치가 없으면 이동 버튼을 비활성화한다.
    func updateCount(current: Int, total: Int) {
        countLabel.text = "\(current)/\(total)"
        let hasMatches = total > 0
        previousButton.isEnabled = hasMatches
        nextButton.isEnabled = hasMatches
        previousButton.alpha = hasMatches ? 1 : 0.3
        nextButton.alpha = hasMatches ? 1 : 0.3
    }

    func setLoading(_ isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }

    func focusTextField() {
        searchTextField.becomeFirstResponder()
    }

    func reset() {
        searchTextField.text = ""
        updateCount(current: 0, total: 0)
        setLoading(false)
    }

}


// MARK: - Initial UI Settings

private extension PopupCardSearchBar {

    func setupSearchTextField() {
        // UIImageView를 직접 leftView로 넣으면 frame이 적용되지 않아, UIView로 감싼 뒤 subview로 넣는다.
        let leftContainer = UIView(frame: CGRect(x: 0, y: 0, width: 35, height: 20))
        let magnifyingImageView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        magnifyingImageView.contentMode = .scaleAspectFit
        magnifyingImageView.frame = leftContainer.bounds
        magnifyingImageView.tintColor = .secondaryLabel
        leftContainer.addSubview(magnifyingImageView)
        searchTextField.leftView = leftContainer
        searchTextField.leftViewMode = .always

        let rightContainer = UIView(frame: CGRect(x: 0, y: 0, width: 28, height: 20))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.center = CGPoint(x: rightContainer.bounds.midX, y: rightContainer.bounds.midY)
        loadingIndicator.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        rightContainer.addSubview(loadingIndicator)
        searchTextField.rightView = rightContainer
        searchTextField.rightViewMode = .always

        searchTextField.borderStyle = .none
        searchTextField.backgroundColor = .secondarySystemBackground
        searchTextField.layer.cornerRadius = 10
        searchTextField.layer.cornerCurve = .continuous
        searchTextField.font = UIFont.systemFont(ofSize: 15)
        searchTextField.tintColor = .currentTheme
        searchTextField.placeholder = L10n.PopupCard.searchPlaceholder
        searchTextField.returnKeyType = .search
        searchTextField.autocorrectionType = .no
        searchTextField.spellCheckingType = .no
        searchTextField.delegate = self
    }

    func setupControls() {
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        previousButton.setImage(
            UIImage(systemName: "arrowtriangle.left.fill", withConfiguration: symbolConfiguration),
            for: .normal
        )
        nextButton.setImage(
            UIImage(systemName: "arrowtriangle.right.fill", withConfiguration: symbolConfiguration),
            for: .normal
        )
        previousButton.tintColor = .currentTheme
        nextButton.tintColor = .currentTheme
        previousButton.accessibilityLabel = L10n.PopupCard.searchPreviousMatch
        nextButton.accessibilityLabel = L10n.PopupCard.searchNextMatch

        countLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        countLabel.textColor = .label
        countLabel.textAlignment = .center
        countLabel.setContentHuggingPriority(.required, for: .horizontal)

        let closeSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        closeButton.setImage(
            UIImage(systemName: "xmark.circle.fill", withConfiguration: closeSymbolConfiguration),
            for: .normal
        )
        closeButton.tintColor = .secondaryLabel
        closeButton.accessibilityLabel = L10n.PopupCard.searchClose

        controlStackView.axis = .horizontal
        controlStackView.alignment = .center
        controlStackView.spacing = 6
        controlStackView.addArrangedSubview(previousButton)
        controlStackView.addArrangedSubview(countLabel)
        controlStackView.addArrangedSubview(nextButton)
        controlStackView.addArrangedSubview(closeButton)
    }

    func configureHierarchy() {
        addSubview(searchTextField)
        addSubview(controlStackView)
    }

    func setupConstraints() {
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        controlStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchTextField.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            searchTextField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -7),
            searchTextField.leadingAnchor.constraint(equalTo: leadingAnchor),
            searchTextField.heightAnchor.constraint(equalToConstant: 35),

            controlStackView.leadingAnchor.constraint(equalTo: searchTextField.trailingAnchor, constant: 8),
            controlStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            controlStackView.centerYAnchor.constraint(equalTo: centerYAnchor),

            countLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            previousButton.widthAnchor.constraint(equalToConstant: 32),
            nextButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
        ])
    }

    func setupActions() {
        searchTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        previousButton.addTarget(self, action: #selector(previousButtonTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        onQueryChanged?(textField.text ?? "")
    }

    @objc func previousButtonTapped() {
        onTapPrevious?()
    }

    @objc func nextButtonTapped() {
        onTapNext?()
    }

    @objc func closeButtonTapped() {
        onTapClose?()
    }

}


// MARK: - UITextFieldDelegate

extension PopupCardSearchBar: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

}
