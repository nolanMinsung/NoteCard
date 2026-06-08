//
//  NoOpUploadProgressObservable.swift
//  NoteCard
//

import Combine
import Foundation
import SyncInterface

/// Firebase 미설정·익명 단독 환경에서 사용. 항상 nil 을 한 번 emit 해 UI 가 표시를 숨기게 함.
final class NoOpUploadProgressObservable: UploadProgressObservable, @unchecked Sendable {
    var imageUploadProgressPublisher: AnyPublisher<UploadProgressSnapshot?, Never> {
        Just(nil).eraseToAnyPublisher()
    }
}
