//
//  NoteCardError.swift
//  NoteCard
//
//  Created by 김민성 on 9/10/25.
//

import Foundation

/// NoteCard 모든 커스텀 에러가 준수하는 기본 프로토콜
protocol NoteCardError: LocalizedError {
    /// 사용자에게 보여줄 에러 제목 (Optional)
    var title: String? { get }
    
    /// 사용자에게 보여줄 에러 설명 메시지
    var displayingMessage: String { get }
}

extension NoteCardError {
    
    var title: String? {
        return "오류"
    }
    
    // LocalizedError 프로토콜의 errorDescription을 기본 구현으로 사용
    var errorDescription: String? {
        return self.displayingMessage
    }
}

