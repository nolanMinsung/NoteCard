//
//  MemoDetailViewController.swift
//  NoteCard
//
//  Created by 김민성 on 9/11/25.
//

import UIKit

class MemoDetailViewController: UIViewController {
    
    enum MemoDetailType {
        case making
        case editing
    }
    
    private let rootView = MemoDetailView()
    private let detailType: MemoDetailType
    private let memo: Memo?
    
    init(type: MemoDetailType, memo: Memo?) {
        self.detailType = type
        self.memo = memo
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = rootView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isModalInPresentation = true
        
        
    }
    
    
}


private extension MemoDetailViewController {
    
    func configureView(with memo: Memo) async throws {
        rootView.titleTextField.text = memo.memoTitle
        let fetchedCategory = try await CategoryEntityRepository.shared.getAllCategories(ofMemo: memo, inOrderOf: .modificationDate, isAscending: false)
        rootView.categoryListCollectionView.reloadData()
        let memoImageInfoList = try await ImageEntityRepository.shared.getAllImageInfo(for: memo)
        
        rootView.memoTextView.text = memo.memoText
    }
    
}
