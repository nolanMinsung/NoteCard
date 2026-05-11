//
//  MemoEditingToolbarView.swift
//  NoteCard
//
//  Created by 김민성 on 5/11/26.
//

import UIKit

/// 메모 편집 모드에서 시스템 `UINavigationController.toolbar`를 대체하는 커스텀 하단 toolbar.
///
/// iOS 26+에서는 Liquid Glass 머티리얼을, 그 이전 버전에서는 chrome blur 머티리얼을 사용한다.
/// `MemoView` 안에 임베드되어 `safeAreaLayoutGuide.bottomAnchor`에 부착되므로 OS 버전과 무관하게
/// 항상 콘텐츠 safe area 하단(탭바 위)에 위치한다.
final class MemoEditingToolbarView: UIView {

    /// 권장 높이 — 시스템 toolbar(44~49pt)와 시각적으로 동등.
    static let preferredHeight: CGFloat = 49

    /// 마지막으로 적용한 가시성. 같은 값으로 setVisible이 들어오면 무시한다.
    private var isToolbarVisible: Bool = false

    /// 숨겨진 상태에서 적용할 transform — 화면 아래로 살짝 더 밀어둠.
    private var hiddenTransform: CGAffineTransform {
        CGAffineTransform(translationX: 0, y: Self.preferredHeight + 12)
    }

    // MARK: - Callbacks

    var onDeleteTapped: (() -> Void)?

    // MARK: - Subviews

    private let backgroundEffectView: UIVisualEffectView = {
        let effect: UIVisualEffect
        if #available(iOS 26.0, *) {
            effect = UIGlassEffect(style: .regular)
        } else {
            effect = UIBlurEffect(style: .systemChromeMaterial)
        }
        let view = UIVisualEffectView(effect: effect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .label
        label.textAlignment = .natural
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        // 가로 폭이 좁아지면 카운트 라벨을 우선적으로 줄임 (액션 버튼 보존).
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let deleteButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "trash")
        config.baseForegroundColor = .systemRed
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let menuButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "ellipsis.circle")
        config.baseForegroundColor = .label
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        let button = UIButton(configuration: config)
        button.showsMenuAsPrimaryAction = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        setupViewHierarchy()
        setupLayoutConstraints()
        setupActions()
        setupAccessibility()

        // 초기 상태: 화면 밖 + 투명 + 비활성. setVisible(true, ...)로 등장.
        alpha = 0
        transform = hiddenTransform
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViewHierarchy() {
        // 그림자가 잘리지 않도록 self는 clip하지 않고, 내부 backgroundEffectView에 코너 처리 + 클립.
        // 양 끝이 반원인 pill 모양. 탭바와 떨어져 떠 있는 floating bar 느낌.
        backgroundEffectView.layer.cornerRadius = Self.preferredHeight / 2
        backgroundEffectView.layer.cornerCurve = .continuous
        backgroundEffectView.clipsToBounds = true

        // 배경과의 경계가 흐릿한 글래스 머티리얼을 시각적으로 분리하기 위한 그림자.
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.22
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 4)

        addSubview(backgroundEffectView)
        let contentContainer: UIView = backgroundEffectView.contentView
        contentContainer.addSubview(countLabel)
        contentContainer.addSubview(deleteButton)
        contentContainer.addSubview(menuButton)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // pill 모양 그대로 그림자를 그리도록 path 캐시. 매 프레임 렌더링 비용 ↓.
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: Self.preferredHeight / 2)
        layer.shadowPath = path.cgPath
    }

    private func setupLayoutConstraints() {
        let contentContainer = backgroundEffectView.contentView

        NSLayoutConstraint.activate([
            backgroundEffectView.topAnchor.constraint(equalTo: topAnchor),
            backgroundEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // 카운트 라벨: 좌측 정렬, pill 둥근 가장자리에서 18pt 안쪽.
            // 액션 버튼 영역을 침범하지 않도록 trailing은 <=로 두어 좁아질 때 잘리도록 함.
            countLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 18),
            countLabel.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor),
            countLabel.trailingAnchor.constraint(lessThanOrEqualTo: deleteButton.leadingAnchor, constant: -8),

            // 액션 버튼: 우측 정렬, 우선순위 높음 (압축 저항 default → 라벨이 먼저 줄어듦).
            deleteButton.trailingAnchor.constraint(equalTo: menuButton.leadingAnchor, constant: -4),
            deleteButton.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor),

            menuButton.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -14),
            menuButton.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor),
        ])
    }

    private func setupActions() {
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    }

    private func setupAccessibility() {
        deleteButton.accessibilityLabel = L10n.Common.delete
        menuButton.accessibilityLabel = L10n.Common.more
        countLabel.accessibilityTraits = .updatesFrequently
    }

    @objc private func deleteTapped() {
        onDeleteTapped?()
    }

    // MARK: - Public API

    /// 선택된 메모 개수를 반영한다. 라벨/액션 버튼 활성 상태를 함께 갱신한다.
    func setSelectedCount(_ count: Int) {
        countLabel.text = String(format: L10n.MemoView.memosSelectedFormat, count)
        let hasSelection = count > 0
        deleteButton.isEnabled = hasSelection
        menuButton.isEnabled = hasSelection
    }

    /// 메뉴 버튼에 표시할 `UIMenu`를 주입한다. memoVCType에 따른 분기는 호출 측이 담당.
    func configureMenu(_ menu: UIMenu) {
        menuButton.menu = menu
    }

    /// Toolbar의 가시성을 토글한다. transform + alpha 보간으로 슬라이드 + 페이드.
    func setVisible(_ visible: Bool, animated: Bool) {
        guard visible != isToolbarVisible else { return }
        isToolbarVisible = visible

        let apply: () -> Void = { [weak self] in
            guard let self else { return }
            self.alpha = visible ? 1 : 0
            self.transform = visible ? .identity : self.hiddenTransform
        }

        if animated {
            UIView.springAnimate(
                withDuration: 0.35,
                dampingRatio: 0.85,
                options: [.beginFromCurrentState],
                animations: apply
            )
        } else {
            apply()
        }

        isUserInteractionEnabled = visible
        accessibilityElementsHidden = !visible

        if visible && UIAccessibility.isVoiceOverRunning {
            // VoiceOver 사용자가 toolbar 등장을 알아챌 수 있도록 포커스를 카운트 라벨로 이동
            UIAccessibility.post(notification: .layoutChanged, argument: countLabel)
        }
    }

}
