//
//  MemoRepository.swift
//  NoteCard
//
//  Created by 김민성 on 8/27/25.
//

import Foundation

protocol MemoRepository: Actor {
    
    func createNewMemo() async throws -> Memo
    
    func getMemo(id: UUID) async throws -> Memo
    func getAllMemos() async throws -> [Memo]
    func getAllMemos(inCategory category: Category?) async throws -> [Memo]
    func getAllMemosInTrash() async throws -> [Memo]
    
    func searchMemo(searchText: String, inCategory category: Category?) async throws -> [Memo]
    func getFavoriteMemos() async throws -> [Memo]
    
    func moveToTrash(_ memo: Memo) async throws
    func deleteMemo(_ memo: Memo) async throws
    
    func restore(_ memo: Memo) async throws
    
    func replaceCategories(to: Memo, newCategories: Set<Category>) async throws
    func replaceCategories(to: [Memo], newCategories: Set<Category>) async throws
    func addCategories(to: Memo, newCategories: Set<Category>) async throws
    func addCategories(to: [Memo], newCategories: Set<Category>) async throws
    func removeCategories(to: Memo, newCategories: Set<Category>) async throws
    func removeCategories(to: [Memo], newCategories: Set<Category>) async throws
    func setFavorite(_ memo: Memo, to value: Bool) async throws
    func updateMemoContent(_ memo: Memo, newTitle: String?, newMemoText: String?) async throws
    
}
