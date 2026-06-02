//
//  AccountDeletionService.swift
//  NoteCard
//

import Foundation

/// 사용자가 계정 삭제를 요청했을 때 클라우드 데이터 정리와 Auth user 삭제를 함께 수행하는 오케스트레이터.
///
/// `AuthService.deleteAccount` 는 Firebase Auth user 만 삭제 — Firestore 문서 / Storage 파일은 남는다.
/// 본 서비스는 호출 시점 사용자의 모든 데이터 (메모 / 카테고리 / 이미지 + 바이너리) 를 먼저 삭제한 뒤
/// Auth user 를 삭제한다. `requiresRecentLogin` 이 발생하면 Apple sign-in 으로 reauthenticate 후 재시도.
public protocol AccountDeletionService: AnyObject, Sendable {

    /// 모든 클라우드 데이터 + Auth user 삭제. 실패 시 부분 삭제 상태일 수 있으므로 호출자는
    /// 다시 시도하도록 안내. reauth 가 필요하면 내부에서 Apple sign-in 시트를 띄움.
    func deleteAccountAndAllData() async throws
}
