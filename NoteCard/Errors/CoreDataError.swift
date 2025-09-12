//
//  CoreDataError.swift
//  NoteCard
//
//  Created by 김민성 on 9/10/25.
//

import Foundation

/// Core Data 작업과 관련된 에러 타입
enum CoreDataError: NoteCardError {
    case fetchFailed(Error?)
    case saveFailed(Error?)
    case objectNotFound
    
    var displayingMessage: String {
        switch self {
        case .fetchFailed:
            return "데이터를 불러오는 데 실패했습니다. 다시 시도해 주세요."
        case .saveFailed:
            return "변경사항을 저장하는 데 실패했습니다. 다시 시도해 주세요."
        case .objectNotFound:
            return "요청한 데이터를 찾을 수 없습니다."
        }
    }
}

