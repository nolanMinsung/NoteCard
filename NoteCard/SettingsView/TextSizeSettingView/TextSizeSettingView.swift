//
//  TextSizeSettingView.swift
//  CardMemo
//
//  Created by 김민성 on 2024/01/01.
//

import UIKit

final class TextSizeSettingView: UIView {
    
    
    let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let textSizeSlider: UISlider = {
        let slider = UISlider()
        slider.backgroundColor = .lightGray
        slider.minimumValue = 0
        slider.maximumValue = 5
        slider.minimumTrackTintColor = .systemGray4
        slider.maximumTrackTintColor = .systemGray4
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        configureHierarchy()
        setupConstraints()
        setupTargetActions()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    private func setupUI() {
        self.backgroundColor = .systemGray6
        self.label.text = "\(self.textSizeSlider.value.rounded())"
    }
    
    
    private func configureHierarchy() {
        self.addSubview(self.label)
        self.addSubview(self.textSizeSlider)
    }
    
    
    private func setupConstraints() {
        
        self.label.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        self.label.bottomAnchor.constraint(equalTo: self.textSizeSlider.bottomAnchor, constant: -50).isActive = true
        
        self.textSizeSlider.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.textSizeSlider.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 30).isActive = true
        self.textSizeSlider.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -30).isActive = true
        self.textSizeSlider.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -50).isActive = true
    }
    
    
    private func setupTargetActions() {
        self.textSizeSlider.addTarget(self, action: #selector(sliderThumbMoved), for: UIControl.Event.touchDragInside)
    }
    
    @objc private func sliderThumbMoved() {
        print(#function)
        self.label.text = "\(self.textSizeSlider.value.rounded())"
    }
    
}
