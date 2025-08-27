//
//  MemoUseCase.swift
//  NoteCard
//
//  Created by 김민성 on 8/27/25.
//

import Foundation

protocol MemoUseCase {
    
    // MARK: - CREATE
    func createNewMemo() throws -> Memo
    
    // MARK: - READ
    func getMemo(id: UUID) throws -> Memo
    func getAllMemo() throws -> [Memo]
    func getFilteredMemo(inCategory category: Category) throws -> [Memo]
    func getMemoInTrash() throws -> [Memo]
    func searchMemo(searchText: String, inCategory: Category?) throws -> [Memo]
    func getFavoriteMemo() throws -> [Memo]
    
    // MARK: - DELETE(Soft)
    func moveToTrash(_ memo: Memo) throws
    
    // MARK: - ⚠️ DELETE(Hard)
    func deleteMemo(_ memo: Memo) throws
    
    // MARK: - RESTORING
    func restore(_ memo: Memo) throws
    
    // MARK: - UPDATE
    func replaceCategories(memoID: UUID, newCategories: [Category]) throws
    func setFavorite(_ memo: Memo, to value: Bool) throws
    
}
