//
//  TotalListTableView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/17.
//

import UIKit

final class TotalListView: UIView {
    
    
//    let someView: UIView = {
//        let view = UIView()
//        view.backgroundColor = .currentTheme()
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
    
    
    lazy var totalListCVTopConstraintToView = self.totalListCollectionView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0)
    lazy var totalListCVTopConstraintToSafeArea = self.totalListCollectionView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 0)
    
    
    lazy var flowLayout: UICollectionViewFlowLayout = { [weak self] in
        guard let self else { fatalError() }
        guard let screenSize = UIScreen.current?.bounds else { fatalError() }
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.scrollDirection = .vertical
        layout.estimatedItemSize = CGSize(width: screenWidth * 0.95, height: 172)
//            layout.estimatedItemSize = CGSize(width: 50, height: 50)
//            layout.estimatedItemSize = .zero
        //collectionView의 topAnchor를 self.view의 topAnchor에 맞췄음에도 컬렉션 뷰를 제일 위로 스크롤하면 searchBar 아래까지 내려오는 건 시스템이 알아서 해 주는 듯.
        //sectionInset.top 을 설정하면 제일 위로 스크롤했을 때, 컨텐츠의 제일 위가 searchBar보다 얼마나 아레에 위치할 지 정할 수 있다.
        layout.sectionInset.top = 10
        layout.sectionInset.bottom = 20
        return layout
    }()
    
    
    
    
    lazy var totalListCollectionView: MemoSearchingCollectionView = {
        
        let totalListCollectionViewBackgroundColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.black
            } else {
                return UIColor.systemGray6
            }
        }
        
        
        
        let collectionView = MemoSearchingCollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.register(TotalListCollectionViewCell.self, forCellWithReuseIdentifier: TotalListCollectionViewCell.cellID)
        collectionView.backgroundColor = totalListCollectionViewBackgroundColor
        collectionView.clipsToBounds = true
        collectionView.isPrefetchingEnabled = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
     
    //MARK: totalListTableView
//    let totalListTableView: UITableView = {
//        let tableView = UITableView()
//        tableView.backgroundColor = .totalListTableViewBackground
//        tableView.register(TotalListTableViewCell.self, forCellReuseIdentifier: TotalListTableViewCell.cellID)
//        tableView.separatorColor = .clear
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//        return tableView
//    }()
    
     
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.totalListCollectionView.alpha < 1 {
            if self.totalListCollectionView.traitCollection.userInterfaceStyle == .dark {
                self.totalListCollectionView.alpha = 0.8
            } else {
                self.totalListCollectionView.alpha = 0.5
            }
        }
    }
    
    
    private func setupUI() {
        
        self.backgroundColor = .white
//        self.addSubview(someView)
        
        self.addSubview(totalListCollectionView)
        
        //MARK: tableView
//        self.addSubview(self.totalListTableView)
    }
    
    private func setupConstraints() {
        
        self.totalListCVTopConstraintToView.isActive = true
        
        self.totalListCollectionView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
        self.totalListCollectionView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
        self.totalListCollectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
         
        //MARK: Constraints
//        self.totalListTableView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
//        self.totalListTableView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
//        self.totalListTableView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
//        self.totalListTableView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
    
    
    
}

