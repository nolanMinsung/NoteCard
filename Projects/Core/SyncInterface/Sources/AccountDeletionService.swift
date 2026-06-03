//
//  AccountDeletionService.swift
//  NoteCard
//

import Foundation

/// 사용자가 계정 삭제를 요청했을 때 클라우드 데이터 정리와 Auth user 삭제를 함께 수행하는 오케스트레이터.
///
/// `AuthService.deleteAccount` 는 Firebase Auth user 만 삭제 — Firestore 문서 / Storage 파일은 남는다.
/// 본 서비스는 reauth 로 token 을 갱신한 뒤 사용자의 모든 데이터 (메모 / 카테고리 / 이미지 + 바이너리) 를
/// 삭제하고 마지막에 Auth user 를 삭제한다.
public protocol AccountDeletionService: AnyObject, Sendable {

    /// 모든 클라우드 데이터 + Auth user 삭제. 호출 시 Apple sign-in 시트로 reauth 가 먼저 진행되며,
    /// 사용자가 시트를 취소하면 아무것도 삭제되지 않은 채 종료. 데이터 삭제 도중 실패 시엔 부분
    /// 삭제 상태일 수 있어 호출자는 다시 시도하도록 안내.
    func deleteAccountAndAllData() async throws
}
