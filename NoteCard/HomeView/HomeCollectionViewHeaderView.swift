//
//  HomeCollectionViewHeaderView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

class HomeCollectionViewHeaderView: UICollectionReusableView {
    
    static var cellID: String {
        return String(describing: self)
    }
    
    var section: Int = 0
    
    
    
    let headerViewButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "chevron.right")
        configuration.imagePlacement = NSDirectionalRectEdge.trailing
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        let button = UIButton()
        button.tintColor = UIColor.label
        button.configuration = configuration
        button.setTitleColor(UIColor.systemGreen, for: UIControl.State.normal)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerLabel, headerChevronImageView])
        stackView.axis = .horizontal
        stackView.spacing = 5
        stackView.alignment = UIStackView.Alignment.fill
        stackView.distribution = UIStackView.Distribution.fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textAlignment = NSTextAlignment.center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    let headerChevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        imageView.image = UIImage.init(systemName: "chevron.right")
        imageView.tintColor = UIColor.currentTheme()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    
    
    //headerChevronButton을 버튼이 아닌 UIView로 만들어볼까?
    //어차피 이제 탭제스처로 구현해서 버튼의 존재 이유가 사라졌슴.
    //lazy var headerChevronButton: UIButton = {
    //    let button = UIButton()
    //    button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
    //    button.tintColor = UIColor.label
    //    button.addTarget(self, action: #selector(chevronButtonTapped), for: .touchUpInside)
    //    button.translatesAutoresizingMaskIntoConstraints = false
    //    return button
    //}()
    
    
    let tapGestureRecognizer = UITapGestureRecognizer()
    
    
    
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func chevronButtonTapped() {
    }
    
    func setupUI() {
        self.addSubview(stackView)
        //self.addSubview(headerViewButton)
    }
    
    func setupConstraints() {
        self.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        self.stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20).isActive = true
        self.stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
        
        //self.headerViewButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20).isActive = true
        //self.headerViewButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
        
    }
    
    override func prepareForReuse() {
        self.headerChevronImageView.tintColor = UIColor.currentTheme()
    }
    
    private func setupGesture() {
        self.stackView.addGestureRecognizer(self.tapGestureRecognizer)
        self.tapGestureRecognizer.addTarget(self, action: #selector(postNotification))
    }
    
    
    @objc private func postNotification() {
        NotificationCenter.default.post(name: NSNotification.Name("headerTapped"), object: self)
    }
    
}

