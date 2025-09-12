//
//  ImageEntity+Mapping.swift
//  NoteCard
//
//  Created by 김민성 on 8/28/25.
//

extension ImageEntity {
    
    func toDomain() -> MemoImageInfo {
        MemoImageInfo(
            id: self.uuid,
            thumbnailID: self.thumbnailUUID,
            temporaryOrderIndex: Int(self.temporaryOrderIndex),
            orderIndex: Int(self.orderIndex),
            memoID: self.memo.memoID,
            isTemporaryDeleted: self.isTemporaryDeleted,
            isTemporaryAppended: self.isTemporaryAppended,
            fileExtension: self.fileExtension
        )
    }
    
}
