//
//  EditingSelectedImageViewController.swift
//  CardMemo
//
//  Created by 김민성 on 2023/11/02.
//

import UIKit
import Photos


//사진 한 개만 보여주는 거 말고 선택한 사진 모두 보여줄 수 있게 하면 좋겠다!!
final class DetailViewSelectedImageViewController: UIViewController {
    
    let phAsset: PHAsset?
    let image: UIImage?
    let imageEntityManager = ImageEntityManager.shared
    let imageManager = PHImageManager.default()
    
    lazy var detailViewSelectedImageView = self.view as! DetailViewSelectedImageView
    lazy var imageView = self.detailViewSelectedImageView.imageView
    lazy var scrollView = self.detailViewSelectedImageView.scrollView
    
    init(phAsset: PHAsset?) {
        self.phAsset = phAsset
        self.image = nil
        super.init(nibName: nil, bundle: nil)
    }
    
    init(image: UIImage?) {
        self.image = image
        self.phAsset = nil
        super.init(nibName: nil, bundle: nil)
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = DetailViewSelectedImageView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupImageView()
        setupDelegates()
        
    }
    
    
    private func setupImageView() {
        
        switch (self.phAsset, self.image) {
        case let (phAsset, image) where phAsset == nil && image != nil:
            self.imageView.image = image
            
        //이 케이스는 phAsset이 nil이 아닌 경우만을 다루므로, phAsset을 강제 언래핑
        case let (phAsset, image) where phAsset != nil && image == nil:
            let requestOptions: PHImageRequestOptions = {
                let options = PHImageRequestOptions()
                options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
                options.isNetworkAccessAllowed = true
                options.isSynchronous = false
                return options
            }()
            
            self.imageManager.requestImage(for: phAsset!, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.aspectFit, options: requestOptions) { image, dict in
                DispatchQueue.main.async { self.imageView.image = image }
            }
            
        case (nil, nil):
            return
            
        default:
            return
            
        }
        
        
        
        
        //let requestOptions: PHImageRequestOptions = {
        //    let options = PHImageRequestOptions()
        //    options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        //    options.isNetworkAccessAllowed = true
        //    options.isSynchronous = false
        //    return options
        //}()
        //
        //self.imageManager.requestImage(for: phAsset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.aspectFit, options: requestOptions) { image, dict in
        //    DispatchQueue.main.async { self.imageView.image = image }
        //}
    }
    
    
    private func setupDelegates() {
        self.scrollView.delegate = self
    }
    
}

extension DetailViewSelectedImageViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
}

