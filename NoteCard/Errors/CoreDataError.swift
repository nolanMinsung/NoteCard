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
    case categoryNotFound(name: String)
    case duplicateCategoryDetected
    case duplicateImageDetected
    
    var displayingMessage: String {
        switch self {
        case .fetchFailed:
            return "데이터를 불러오는 데 실패했습니다. 다시 시도해 주세요."
        case .saveFailed:
            return "변경사항을 저장하는 데 실패했습니다. 다시 시도해 주세요."
        case .objectNotFound:
            return "요청한 데이터를 찾을 수 없습니다."
        case .categoryNotFound(let name):
            return "카테고리를 찾을 수 없습니다. UUID: \(name)"
        case .duplicateCategoryDetected:
            return "같은 이름의 카테고리가 2개 이상 발견되었습니다. 조치 필요."
        case .duplicateImageDetected:
            return "같은 이미지가 2개 이상 발견되었습니다. 조치 필요."
        }
    }
}

