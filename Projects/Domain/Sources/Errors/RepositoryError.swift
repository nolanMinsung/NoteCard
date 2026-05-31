//
//  RepositoryError.swift
//  NoteCard
//

import Foundation
import Shared

public enum RepositoryError: NoteCardError {
    case notFound
    case duplicateName

    public var displayingMessage: String {
        switch self {
        case .notFound:
            return "요청한 데이터를 찾을 수 없습니다."
        case .duplicateName:
            return "같은 이름이 이미 존재합니다."
        }
    }
}
