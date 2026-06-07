//
//  PendingUploadResumeTrigger.swift
//  NoteCard
//

import Foundation

/// 첫 sign-in 마이그레이션의 미완료 이미지 바이너리 업로드를 재개시키는 진입점.
/// app lifecycle 시점 (포그라운드 복귀 / launch) 에서 호출되어 끊긴 업로드를 이어 받는다.
///
/// 호출 측은 sign-in 여부·진행 중 여부를 알 필요 없이 호출만 하면 되도록 idempotent 설계:
/// - sign-in 안 됨 → no-op
/// - 이미 진행 중 → no-op
/// - 메타·바이너리 모두 완료됨 → no-op
public protocol PendingUploadResumeTrigger: Sendable {
    func resumePendingUploadsIfNeeded()
}
