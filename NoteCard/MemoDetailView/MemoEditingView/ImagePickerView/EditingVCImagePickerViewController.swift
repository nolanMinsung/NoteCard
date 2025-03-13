////
////  EditingVCImagePickerViewController.swift
////  CardMemo
////
////  Created by 김민성 on 2023/11/02.
////
//
//import UIKit
//import Photos
//
//
//class EditingVCImagePickerViewController: UIViewController {
//    
//    static var selectedIndexPathsArray: [IndexPath] = []
//    
//    
//    let imageManager = PHImageManager.default()
//    let imageEntityManager = ImageEntityManager.shared
//    //PHCachingImageManger의 생성은 PHImageManager의 싱글통 객체 생성을 포함한다.
//    let cachingImageManager = PHCachingImageManager()
//    
//    var fetchResult: PHFetchResult<PHAsset> = PHFetchResult()
//    var firstIndex: Int
//    let memoEntity: MemoEntity
//    
//    lazy var editingVCimagePickerView = self.view as! EditingVCImagePickerView
//    lazy var imagePickerCollectionView = self.editingVCimagePickerView.imagePickerCollectionView
//    lazy var blurView = self.editingVCimagePickerView.blurView
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
//        item.action = #selector(completeImagePicking)
//        item.title = "완료"
//        return item
//    }()
//    
//    
//    
//    init(firstIndex: Int, memoEntity: MemoEntity) {
//        self.firstIndex = firstIndex
//        self.memoEntity = memoEntity
//        super.init(nibName: nil, bundle: nil)
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    
//    
//    
//    override func loadView() {
//        self.view = EditingVCImagePickerView()
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
//    
//    private func checkAuthorization() {
//        let authorizationStatus = PHPhotoLibrary.authorizationStatus(for: PHAccessLevel.readWrite)
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
//            print("PhotoLibrary Usage Authorization is restricted.")
//        
//        @unknown default:
//            print("@unknow default")
//            fatalError()
//        }
//    }
//    
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
//        let editingSelectedImageVC = DetailViewSelectedImageViewController(phAsset: assetToRequest)
//        editingSelectedImageVC.modalPresentationStyle = UIModalPresentationStyle.formSheet
//        
//        self.present(editingSelectedImageVC, animated: true)
//        
//        let animator = UIViewPropertyAnimator(duration: 0.3, curve: UIView.AnimationCurve.easeInOut)
//        animator.addAnimations { [weak self] in
//            guard let self else { return }
//            self.blurView.alpha = 1.0 }
//        //animator.startAnimation()
//    }
//    
//    private func fetchAssets() {
//        let fetchOptions: PHFetchOptions = {
//            let fetchOptions = PHFetchOptions()
//            let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
//            fetchOptions.sortDescriptors = [sortDescriptor]
//            return fetchOptions
//        }()
//        
//        self.fetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
//        DispatchQueue.main.async {
//            self.imagePickerCollectionView.reloadData()
//        }
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
//                guard let castedCell = cell as? EditingVCImagePickerCollectionViewCell else { return }
//                castedCell.selectionOrderLabel.text = "\(index)"
//            }
//            index += 1
//        }
//    }
//    
//    
//    @objc private func cancelImagePicking() {
//        self.dismiss(animated: true)
//        Self.selectedIndexPathsArray = []
//    }
//    
//    @objc private func completeImagePicking() {
//        print("완료버튼이 눌림")
//        
//        //선택한 이미지를 컬렉션뷰에 반영
//        guard let presentingNaviCon = self.presentingViewController as? UINavigationController else { return }
//        guard let memoEditingVC = presentingNaviCon.viewControllers.first as? MemoEditingViewController else { return }
//        var assetsArrayToAppend = [PHAsset]()
//        
////        for indexPath in Self.selectedIndexPathsArray {
////            let asset = self.fetchResult.object(at: indexPath.row)
////            assetsArrayToAppend.append(asset)
////        }
//        memoEditingVC.addedAssetsArray = assetsArrayToAppend
//        Self.selectedIndexPathsArray = []
//        self.dismiss(animated: true)
//        
//        //memoMakingVC.assetsArray = []
//        //for indexPath in Self.selectedIndexPathsArray {
//        //    let asset = self.fetchResult.object(at: indexPath.row)
//        //    memoMakingVC.assetsArray.append(asset)
//        //}
//        //memoMakingVC.selectedImageCollectionView.reloadData()
//        //
//        //self.dismiss(animated: true)
//        
//        
//        //addedAssetsArray에 값이 들어오면 새로 추가될 사진들을 넣어주는 작업
//        guard self.fetchResult.count != 0 else { return }
//        //guard !self.addedAssetsArray.isEmpty else { return }
//        
//        let requestOptions: PHImageRequestOptions = {
//            let options = PHImageRequestOptions()
//            options.deliveryMode = PHImageRequestOptionsDeliveryMode.opportunistic
//            options.isNetworkAccessAllowed = true
//            options.isSynchronous = true
//            return options
//        }()
//        
//        DispatchQueue.global().async { [weak self] in
//            print("비동기작업 시작~")
//            guard let self else { return }
//            
//            var index = self.firstIndex
//            print("반복문 시작~")
//            
//            self.fetchResult.enumerateObjects { asset, int, mutablePointer in
//                
//                PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.aspectFit, options: requestOptions) { image, infoDict in
//                    
//                    guard let image else { return }
//                    let createdImageEntity = self.imageEntityManager.createImageEntity(image: image, orderIndex: index, memoEntity: self.memoEntity)
//                }
//                index += 1
//                
//            }
//            
//            
////            for asset in self.addedAssetsArray {
////                print(index)
////                self.phImageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.aspectFit, options: requestOptions) { image, someDict in
////                    guard let image else { return }
////                    
////                    guard let addedImageEntity = self.imageEntityManager.createImageEntity(image: image, orderIndex: index, memoEntity: self.selectedMemoEntity) else { return }
////                    self.temporaryAddedImageEntities.append(addedImageEntity)
////                }
////                index += 1
////            }
////            self.addedAssetsArray = []
////            DispatchQueue.main.async {
////                print("메인쓰레드에서 리로드합니다")
////                self.selectedImageCollectionView.reloadData()
////            }
//        }
//        
//        
//        
//        
//        
//        
//        
//        
//    }
//    
//}
//
//
//
//extension EditingVCImagePickerViewController: UICollectionViewDataSource {
//    
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return self.fetchResult.count
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        
//        let reusableCell = self.imagePickerCollectionView.dequeueReusableCell(withReuseIdentifier: EditingVCImagePickerCollectionViewCell.cellID, for: indexPath) as! EditingVCImagePickerCollectionViewCell
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
//        
//        cachingImageManager.requestImage(for: assetToRequest, targetSize: CGSize(width: 300, height: 300), contentMode: PHImageContentMode.aspectFit, options: requestOptions) { [weak reusableCell] image, dict in
//            
//            guard let image else { return }
//            
//            DispatchQueue.main.async {
//                reusableCell?.imageView.image = image
//            }
//        }
//        
//        if Self.selectedIndexPathsArray.contains(indexPath) {
//            let indexSelectionOrder = Self.selectedIndexPathsArray.firstIndex { indexPathInArray in indexPathInArray == indexPath }
//            reusableCell.selectionOrderLabel.text = "\(indexSelectionOrder!)"
//            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: UICollectionView.ScrollPosition())
//        }
//        
//        return reusableCell
//    }
//    
//    
//}
//
//extension EditingVCImagePickerViewController: UICollectionViewDelegate {
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
//    
//    
//}
//
