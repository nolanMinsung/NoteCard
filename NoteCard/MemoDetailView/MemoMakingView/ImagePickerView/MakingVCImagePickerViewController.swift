////
////  MakingVCImagePickerViewController.swift
////  CardMemo
////
////  Created by 김민성 on 2023/11/02.
////
//
//import UIKit
//import Photos
//import PhotosUI
//
//
//class MakingVCImagePickerViewController: UIViewController {
//    
//    static var selectedIndexPathsArray: [IndexPath] = []
//    
//    let imageManager = PHImageManager.default()
//    //PHCachingImageManger의 생성은 PHImageManager의 싱글통 객체 생성을 포함한다.
//    let cachingImageManager = PHCachingImageManager()
//    
//    var fetchResult: PHFetchResult<PHAsset> = PHFetchResult()
//    
//    //강제언래핑 에러 안나겠지...?
//    lazy var makingVCImagePickerView = self.view as! MakingVCImagePickerView
//    lazy var imagePickerCollectionView = self.makingVCImagePickerView.imagePickerCollectionView
//    lazy var blurView = self.makingVCImagePickerView.blurView
//    lazy var cancelBarButtonItem: UIBarButtonItem = {
//        let item = UIBarButtonItem()
//        item.target = self
//        item.action = #selector(cancelImagePicking)
//        item.title = "취소"
//        return item
//    }()
//    
//    lazy var doneBarButtonItem: UIBarButtonItem = {
//        let item = UIBarButtonItem()
//        item.target = self
//        item.action = #selector(pickingComplete)
//        item.title = "완료"
//        return item
//    }()
//    
//    
//    override func loadView() {
//        self.view = MakingVCImagePickerView()
//    }
//    
//    
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        checkAuthorization()
//        
//        //requestAuthorization()
//        setupDelegates()
//        setupNaviBar()
//        setupObserver()
//        //fetchAssets()
//        
//    }
//    
//    
//    private func checkAuthorization() {
//        print(#function)
//        let authorizationStatus = PHPhotoLibrary.authorizationStatus(for: PHAccessLevel.readWrite)
//        print("PHPhotoLibrary의 authorization status 를 확인함.")
//        switch authorizationStatus {
//        case .authorized:
//            print("authorized")
//            self.fetchAssets()
//            print("fetchAssets returned")
//        case .denied:
//            print("denided")
//            PHPhotoLibrary.requestAuthorization(for: PHAccessLevel.readWrite) { [weak self] status in
//                guard let self else { return }
//                switch status {
//                case .authorized:
//                    self.fetchAssets()
//                default:
//                    return
//                }
//            }
//            
//        case .limited:
//            print("limited")
//            PHPhotoLibrary.requestAuthorization(for: PHAccessLevel.readWrite) { status in
//                //guard let self else { return }
//                //if authorizationStatus == .authorized {
//                //    self.fetchImageThumbnails()
//                //} else {
//                //    //dismissPicker()
//                //}
//            }
//        case .notDetermined:
//            print("notDetermined")
//            PHPhotoLibrary.requestAuthorization(for: PHAccessLevel.readWrite) { status in
//                //guard let self else { return }
//                //if authorizationStatus == .authorized {
//                //    self.fetchImageThumbnails()
//                //} else {
//                //    //dismissPicker()
//                //}
//            }
//        case .restricted:
//            print("restricted")
//            print("PhotoLibrary Usage Authorization is restricted. Please authorize album Library usage authorization to add images in memo")
//        
//        @unknown default:
//            print("@unknow default")
//            fatalError()
//        }
//        PHPhotoLibrary.shared().register(self)
//    }
//    
//    
//    
//    //private func requestAuthorization() {
//    //    PHPhotoLibrary.requestAuthorization(for: PHAccessLevel.readWrite) { status in
//    //        //guard let self else { return }
//    //        //if authorizationStatus == .authorized {
//    //        //    self.fetchImageThumbnails()
//    //        //} else {
//    //        //    //dismissPicker()
//    //        //}
//    //    }
//    //}
//    
//    private func setupDelegates() {
//        self.imagePickerCollectionView.dataSource = self
//        self.imagePickerCollectionView.delegate = self
//    }
//    
//    private func setupNaviBar() {
//        self.title = "사진 선택"
//        
//        let naviBarDefaultAppearance: UINavigationBarAppearance = {
//            let appearance = UINavigationBarAppearance()
//            appearance.backgroundColor = .clear
//            appearance.configureWithDefaultBackground()
//            return appearance
//        }()
//        
//        self.navigationController?.navigationBar.standardAppearance = naviBarDefaultAppearance
//        self.navigationController?.navigationBar.scrollEdgeAppearance = naviBarDefaultAppearance
//        self.navigationController?.navigationBar.compactAppearance = naviBarDefaultAppearance
//        self.navigationController?.navigationBar.compactScrollEdgeAppearance = naviBarDefaultAppearance
//        
//        self.navigationItem.leftBarButtonItem = cancelBarButtonItem
//        self.navigationItem.rightBarButtonItem = doneBarButtonItem
//    }
//    
//    private func setupObserver() {
//        NotificationCenter.default.addObserver(self, selector: #selector(showDetailImage), name: NSNotification.Name("showDetailImageNotification"), object: nil)
//    }
//    
//    @objc private func showDetailImage(notification: Notification) {
//        guard let indexPath = notification.object as? IndexPath else { return }
//        let assetToRequest = self.fetchResult.object(at: indexPath.row)
//        let makingSelectedImageVC = DetailViewSelectedImageViewController(phAsset: assetToRequest)
//        makingSelectedImageVC.modalPresentationStyle = UIModalPresentationStyle.formSheet
//        
//        self.present(makingSelectedImageVC, animated: true)
//    }
//    
//    private func fetchAssets() {
//        print(#function)
//        
//        DispatchQueue.global().async {
//            let fetchOptions: PHFetchOptions = {
//                let fetchOptions = PHFetchOptions()
//                let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
//                fetchOptions.sortDescriptors = [sortDescriptor]
//                fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue as CVarArg)
//                return fetchOptions
//            }()
//            
//            print("-")
//            let fetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
//            print("-")
//            //let fetchResult = PHAsset.fetchAssets(with: PHFetchOptions())
//            self.fetchResult = fetchResult
//            print("self.fetchResult에 fetchResult 담음")
//            DispatchQueue.main.async {
//                self.imagePickerCollectionView.reloadData()
//            }
//        }
//        
//    }
//    
//    private func reloadSelectionOrder() {
//        
//        var index = 0
//        for indexPath in Self.selectedIndexPathsArray {
//            //cellForItem(at:) 메서드는 visible한 메서드가 아니면 nil을 반환하기 때문에 현재 화면에 보이는지 여부를 먼저 체크
//            //(사실 iOS 15부터는 화면에 보이지 않아도, 재사용을 위한 대기 큐에 들어가기 전까지는 cellForItem(at:) 메서드를 활용해서 불러올 수는 있는듯)
//            if self.imagePickerCollectionView.indexPathsForVisibleItems.contains(indexPath) {
//                guard let cell = self.imagePickerCollectionView.cellForItem(at: indexPath) else { return }
//                guard let castedCell = cell as? MakingVCImagePickerCollectionViewCell else { return }
//                castedCell.selectionOrderLabel.text = "\(index)"
//            }
//            index += 1
//                
//        }
//    }
//    
//    
//    @objc private func cancelImagePicking() {
//        self.dismiss(animated: true)
//    }
//    
//    @objc private func pickingComplete() {
//        print("완료버튼이 눌림")
//        
//        //선택한 이미지를 컬렉션뷰에 반영
//        
//        guard let presentingNaviCon = self.presentingViewController as? UINavigationController else { return }
//        guard let memoMakingVC = presentingNaviCon.viewControllers.first as? MemoMakingViewController else { return }
//        memoMakingVC.assetsArray = []
//        print(Self.selectedIndexPathsArray)
//        for indexPath in Self.selectedIndexPathsArray {
//            let asset = self.fetchResult.object(at: indexPath.row)
//            memoMakingVC.assetsArray.append(asset)
//        }
//        memoMakingVC.selectedImageCollectionView.reloadData()
//        print(memoMakingVC.assetsArray.count)
//        
//        self.dismiss(animated: true)
//    }
//    
//    
//    
//    
//}
//
//
//
//extension MakingVCImagePickerViewController: UICollectionViewDataSource {
//    
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        let fetchResultCount = self.fetchResult.count
//        return fetchResultCount
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        
//        let reusableCell = self.imagePickerCollectionView.dequeueReusableCell(
//            withReuseIdentifier: MakingVCImagePickerCollectionViewCell.cellID,
//            for: indexPath
//        ) as! MakingVCImagePickerCollectionViewCell
//        
//        let assetToRequest = self.fetchResult.object(at: indexPath.row)
//        let requestOptions: PHImageRequestOptions = {
//            let options = PHImageRequestOptions()
//            options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
//            options.isNetworkAccessAllowed = true
//            options.isSynchronous = true
//            return options
//        }()
//        
//        reusableCell.requestID = self.cachingImageManager.requestImage(for: assetToRequest, targetSize: CGSize(width: 300, height: 300), contentMode: PHImageContentMode.aspectFit, options: requestOptions) { [weak reusableCell] image, dict in
//            guard let image else { return }
//        
//            DispatchQueue.main.async {
//                reusableCell?.imageView.image = image
//            }
//        }
//        
//        
//        if Self.selectedIndexPathsArray.contains(indexPath) {
//            let indexSelectionOrder = Self.selectedIndexPathsArray.firstIndex { indexPathInArray in indexPathInArray == indexPath }
//            reusableCell.selectionOrderLabel.text = "\(indexSelectionOrder!)"
//            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: UICollectionView.ScrollPosition())
//        }
//        
//        print("!!!")
//        return reusableCell
//    }
//    
//    
//}
//
//extension MakingVCImagePickerViewController: UICollectionViewDelegate {
//    
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        Self.selectedIndexPathsArray.append(indexPath)
//        self.reloadSelectionOrder()
//    }
//    
//    
//    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//        Self.selectedIndexPathsArray.removeAll { indexPathInArray in indexPathInArray == indexPath }
//        self.reloadSelectionOrder()
//    }
//    
//    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
//        
//        print(#function)
//        let imagePickerCollectionView = scrollView as! UICollectionView
//        
//        imagePickerCollectionView.indexPathsForVisibleItems.forEach { indexPath in
//            
//            let cell = imagePickerCollectionView.cellForItem(at: indexPath) as! MakingVCImagePickerCollectionViewCell
//            
//            let assetToRequest = self.fetchResult.object(at: indexPath.row)
//            let requestOptions: PHImageRequestOptions = {
//                let options = PHImageRequestOptions()
//                options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
//                options.isNetworkAccessAllowed = true
//                options.isSynchronous = true
//                return options
//            }()
//            
//            self.cachingImageManager.requestImage(for: assetToRequest, targetSize: CGSize(width: 500, height: 500), contentMode: PHImageContentMode.aspectFit, options: requestOptions) { [weak cell] image, dict in
//                guard let image else { return }
//                
//                DispatchQueue.main.async {
//                    cell?.imageView.image = image
//                }
//            }
//        }
//        
//    }
//    
//    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        
//        print(#function)
//        let imagePickerCollectionView = scrollView as! UICollectionView
//        
//        imagePickerCollectionView.indexPathsForVisibleItems.forEach { indexPath in
//            
//            let cell = imagePickerCollectionView.cellForItem(at: indexPath) as! MakingVCImagePickerCollectionViewCell
//            
//            let assetToRequest = self.fetchResult.object(at: indexPath.row)
//            let requestOptions: PHImageRequestOptions = {
//                let options = PHImageRequestOptions()
//                options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
//                options.isNetworkAccessAllowed = true
//                options.isSynchronous = true
//                return options
//            }()
//            
//            self.cachingImageManager.requestImage(for: assetToRequest, targetSize: CGSize(width: 500, height: 500), contentMode: PHImageContentMode.aspectFit, options: requestOptions) { [weak cell] image, dict in
//                guard let image else { return }
//                
//                DispatchQueue.main.async {
//                    cell?.imageView.image = image
//                }
//            }
//        }
//        
//    }
//    
//}
//
//
//extension MakingVCImagePickerViewController: PHPhotoLibraryChangeObserver {
//    
//    func photoLibraryDidChange(_ changeInstance: PHChange) {
//        
//    }
//    
//    
//}
//
