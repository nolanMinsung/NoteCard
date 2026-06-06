//
//  PopupImageCell.swift
//  NoteCard
//

import UIKit

/// PopupCard 의 이미지 collection view 셀.
/// 메타만 도착한 시점 즉시 표시 가능하도록 placeholder 배경 + 상태별 overlay (loading / failed) 구조.
final class PopupImageCell: UICollectionViewCell {

    static var cellID: String { String(describing: self) }

    private var onRetry: (() -> Void)?

    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let retryButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "arrow.clockwise")
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        let button = UIButton(configuration: config)
        button.tintColor = .secondaryLabel
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        activityIndicator.stopAnimating()
        retryButton.isHidden = true
        onRetry = nil
    }

    private func setupUI() {
        contentView.backgroundColor = .systemGray5
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 13
        contentView.layer.cornerCurve = .continuous

        contentView.addSubview(imageView)
        contentView.addSubview(activityIndicator)
        contentView.addSubview(retryButton)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            retryButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            retryButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(state: ImageLoadState, onRetry: @escaping () -> Void) {
        self.onRetry = onRetry
        switch state {
        case .loading:
            imageView.image = nil
            activityIndicator.startAnimating()
            retryButton.isHidden = true
        case .loaded(let image):
            imageView.image = image
            activityIndicator.stopAnimating()
            retryButton.isHidden = true
        case .failed:
            imageView.image = nil
            activityIndicator.stopAnimating()
            retryButton.isHidden = false
        }
    }

    @objc private func retryTapped() {
        onRetry?()
    }
}
