//
//  EditingSelectedImageView.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit

final class DetailViewSelectedImageView: UIView {
    
    let imageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .white
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.contentMode = UIView.ContentMode.scaleAspectFit
        view.backgroundColor = .lightGray
        view.addSubview(self.imageView)
        view.zoomScale = 1.0
        view.minimumZoomScale = 1.0
        view.maximumZoomScale = 4.0
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
        self.backgroundColor = .clear
        self.addSubview(self.scrollView)
    }
    
    private func setupConstraints() {
        self.scrollView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 100).isActive = true
        self.scrollView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 40).isActive = true
        self.scrollView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -40).isActive = true
        self.scrollView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -100).isActive = true
        
        self.imageView.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor, constant: 0).isActive = true
        self.imageView.centerYAnchor.constraint(equalTo: self.scrollView.centerYAnchor, constant: 0).isActive = true
        self.imageView.widthAnchor.constraint(equalToConstant: 310).isActive = true
        self.imageView.heightAnchor.constraint(equalToConstant: 500).isActive = true
    }
    
}

