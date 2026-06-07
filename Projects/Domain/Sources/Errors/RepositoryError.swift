//
//  RepositoryError.swift
//  NoteCard
//

import Foundation
import Shared

public enum RepositoryError: NoteCardError {
    case notFound

    public var displayingMessage: String {
        switch self {
        case .notFound:
            return "요청한 데이터를 찾을 수 없습니다."
        }
    }
}
