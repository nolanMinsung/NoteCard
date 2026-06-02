//
//  AccountSentinelService.swift
//  NoteCard
//

import Foundation

/// 사용자 계정이 살아있음을 나타내는 sentinel 문서 (`users/<uid>/_meta/active`) 의 생성·감시·삭제를 담당.
///
/// 동작:
/// - 사인인 시 sentinel 을 멱등 생성 + listener attach.
/// - listener 가 .removed 를 감지하면 (= 다른 기기에서 계정 삭제) 강제 signOut → 익명 모드 전환.
/// - 사인아웃 시 listener detach.
/// - 본 기기에서 계정 삭제 진행 시 `deleteSentinel()` 을 사용. 호출 측 (예: AccountDeletionService) 이
///   다른 데이터 삭제보다 먼저 호출하면 다른 기기들이 즉시 signOut 됨.
public protocol AccountSentinelService: AnyObject, Sendable {

    /// 현재 사용자의 sentinel 문서를 삭제. 호출 직전에 본 기기의 listener 가 자동 detach 되어
    /// self-trigger (자기 listener 가 자기가 지운 sentinel 을 감지해 signOut 하는 사고) 를 방지.
    func deleteSentinel() async throws
}
