//
//  MemoEntity+Mapping.swift
//  NoteCard
//
//  Created by 김민성 on 8/27/25.
//

extension MemoEntity {
    
    func toDomain() -> Memo {
        Memo(
            memoID:           self.memoID,
            creationDate:     self.creationDate,
            modificationDate: self.modificationDate,
            deletedDate:      self.deletedDate,
            isFavorite:       self.isFavorite,
            isInTrash:        self.isInTrash,
            memoText:         self.memoText,
            memoTitle:        self.memoTitle,
            categories:       Set((self.categories as? Set<CategoryEntity>)?.map({ $0.toDomain() }) ?? []),
            images:           Set((self.images as? Set<ImageEntity>)?.map({ $0.toDomain() }) ?? []),
        )
    }
    
}
