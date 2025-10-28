//
//  MemoSearchingCell.swift
//  NoteCard
//
//  Created by 김민성 on 8/6/25.
//

import UIKit

class MemoSearchingCell: UICollectionViewCell, ViewShrinkable {
    
    override var isHighlighted: Bool {
        didSet { isHighlighted ? shrink(scale: 0.97) : restore() }
    }
    
    private var categories: [Category] = []
    
    private let mainStackView = UIStackView()
    private let titleLabel: UILabel = UILabel()
    private(set) var categoryCollectionView: UICollectionView!
    private let memoTextLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupCollectionView()
        setupUI()
        categoryCollectionView.register(PopupCategoryCell.self, forCellWithReuseIdentifier: PopupCategoryCell.reuseIdentifier)
        categoryCollectionView.dataSource = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.contentView.traitCollection.userInterfaceStyle == .dark {
            self.layer.shadowPath = nil
            self.layer.shadowColor = nil
            
        } else {
            let roundBezierPath = UIBezierPath(roundedRect: bounds, cornerRadius: 25)
            self.layer.shadowOffset = .zero
            self.layer.shadowPath = roundBezierPath.cgPath
            self.layer.shadowOpacity = 0.2
            self.layer.shadowRadius = 5
            self.layer.shadowColor = UIColor.currentTheme.cgColor
        }
        
    }
    
}

private extension MemoSearchingCell {
    
    func makeCategoryLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(100), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(100), heightDimension: .absolute(30))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal
        let layout = UICollectionViewCompositionalLayout(section: section, configuration: config)
        return layout
    }
    
    func setupCollectionView() {
        categoryCollectionView = UICollectionView(frame: .zero, collectionViewLayout: makeCategoryLayout())
        categoryCollectionView.backgroundColor = .clear
        categoryCollectionView.showsHorizontalScrollIndicator = false
        categoryCollectionView.layer.cornerRadius = 15
        categoryCollectionView.clipsToBounds = true
    }
    
    func setupUI() {
        contentView.backgroundColor = .memoBackground
        contentView.layer.cornerRadius = 25
        contentView.layer.cornerCurve = .continuous
        
        mainStackView.axis = .vertical
        mainStackView.spacing = 10
        mainStackView.alignment = .fill
        mainStackView.distribution = .fill
        
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        
        memoTextLabel.font = .systemFont(ofSize: 15)
        memoTextLabel.numberOfLines = 0
        
        mainStackView.addArrangedSubview(titleLabel)
        mainStackView.addArrangedSubview(categoryCollectionView)
        mainStackView.addArrangedSubview(memoTextLabel)
        contentView.addSubview(mainStackView)
        
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            mainStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),
        ])
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor, constant: -4),
        ])
        
        categoryCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            categoryCollectionView.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 30),
        ])
        
        memoTextLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        memoTextLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            memoTextLabel.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor, constant: 4),
            memoTextLabel.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor, constant: -4),
        ])
    }
    
}


extension MemoSearchingCell {
    
    func configure(memo: Memo) {
        titleLabel.text = memo.memoTitle
        titleLabel.isHidden = memo.memoTitle.isEmpty
        memoTextLabel.text = String(memo.memoText.prefix(250))
        categories = memo.categories.map({ $0 })
        categoryCollectionView.reloadData()
        categoryCollectionView.isHidden = categories.isEmpty
    }
    
}


// MARK: - UICollectionViewDataSource
extension MemoSearchingCell: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let categoryCell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PopupCategoryCell.reuseIdentifier,
            for: indexPath
        ) as? PopupCategoryCell else {
            fatalError()
        }
        let category = categories[indexPath.item]
        categoryCell.configure(with: category)
        return categoryCell
    }
    
}


