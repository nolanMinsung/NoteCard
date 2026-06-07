//
//  NoOpPendingUploadResumeTrigger.swift
//  NoteCard
//

import Foundation
import SyncInterface

/// Firebase 미설정·익명 단독 환경에서 사용. 호출해도 아무 일도 하지 않음.
final class NoOpPendingUploadResumeTrigger: PendingUploadResumeTrigger, @unchecked Sendable {
    func resumePendingUploadsIfNeeded() {}
}
