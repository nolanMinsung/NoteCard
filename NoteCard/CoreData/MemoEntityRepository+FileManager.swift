//
//  MemoEntityRepository+FileManager.swift
//  NoteCard
//
//  Created by 김민성 on 8/23/25.
//

import Foundation


enum MemoEntityFileManagerError: LocalizedError {
    
    case documentDirectoryNotFound // 이건 추후 FileManagerError 등으로 빼는 게 나을 듯...?
    case failedToCreateNewDirectory
    case fileExistInMemoID
    
    var errorDescription: String? {
        switch self {
        case .documentDirectoryNotFound:
            return "FileManager에서 Document Directory를 찾을 수 없습니다."
        case .failedToCreateNewDirectory:
            return "새로운 디렉토리를 만드는 데 실패했습니다."
        case .fileExistInMemoID:
            return "메모 이름으로 된 파일이 존재합니다."
        }
    }
    
}

extension MemoEntityManager {
    
    func getMemoDirectory(of memo: MemoEntity) async throws -> URL {
        guard let documentURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            throw MemoEntityFileManagerError.documentDirectoryNotFound
        }
        
        let memoDirectoryURL: URL
        if #available(iOS 16, *) {
            memoDirectoryURL = documentURL.appending(
                path: memo.memoID.uuidString,
                directoryHint: .isDirectory
            )
        } else {
            memoDirectoryURL = documentURL.appendingPathComponent(
                memo.memoID.uuidString,
                isDirectory: true
            )
        }
        
        let memoDirectoryStatus = FileManager.default.fileOrDirectoryExist(at: memoDirectoryURL)
        switch memoDirectoryStatus {
        case .isDirectory:
            return memoDirectoryURL
        case .isFile:
            throw MemoEntityFileManagerError.fileExistInMemoID
        case .notExist:
            try FileManager.default.createDirectory(at: memoDirectoryURL, withIntermediateDirectories: false)
            return memoDirectoryURL
        }
    }
    
}
