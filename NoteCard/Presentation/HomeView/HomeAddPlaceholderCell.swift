//
//  HomeAddPlaceholderCell.swift
//  NoteCard
//
//  Created by 김민성 on 5/11/26.
//

import UIKit
import DesignSystem
import Shared

/// 홈 화면에서 카테고리 / 전체 메모가 하나도 없을 때 추가를 유도하는 placeholder 셀.
/// 회색 배경 위에 가운데 + 아이콘과 "OOO 추가" 레이블로 구성된다.
final class HomeAddPlaceholderCell: UICollectionViewCell, ViewShrinkable {

    override var isHighlighted: Bool {
        didSet { isHighlighted ? shrink(scale: 0.95) : restore() }
    }

    private let plusImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "plus")
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 26, weight: .medium)
        imageView.tintColor = .secondaryLabel
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var plusImageCenterYConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = .secondarySystemFill
        contentView.clipsToBounds = true
        contentView.layer.cornerCurve = .continuous

        contentView.addSubview(plusImageView)
        contentView.addSubview(titleLabel)

        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    private func setupConstraints() {
        plusImageCenterYConstraint = plusImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -10)

        NSLayoutConstraint.activate([
            plusImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            plusImageCenterYConstraint,
            plusImageView.widthAnchor.constraint(equalToConstant: 32),
            plusImageView.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.topAnchor.constraint(equalTo: plusImageView.bottomAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
        ])
    }

    /// Placeholder 셀의 모양을 카테고리/메모 셀과 동일한 크기·코너로 맞춘다.
    /// - Parameters:
    ///   - displayedTitle: 시각적으로 표시할 문구. nil이면 라벨을 숨기고 + 아이콘만 노출한다.
    ///   - accessibilityLabel: VoiceOver에서 읽어줄 문구. 시각 라벨 유무와 무관하게 항상 설정한다.
    ///   - cornerRadius: 셀 모서리 반경.
    func configure(displayedTitle: String?, accessibilityLabel: String, cornerRadius: CGFloat) {
        titleLabel.text = displayedTitle
        titleLabel.isHidden = (displayedTitle == nil)
        // 라벨이 숨겨지면 + 아이콘을 정중앙으로, 보이면 라벨 공간을 비워두기 위해 살짝 위로 이동.
        plusImageCenterYConstraint.constant = (displayedTitle == nil) ? 0 : -10
        contentView.layer.cornerRadius = cornerRadius
        self.accessibilityLabel = accessibilityLabel
    }

}
