//
//  UploadProgressSnapshot.swift
//  NoteCard
//

import Foundation

/// 익명 → Firestore 첫 마이그레이션의 이미지 바이너리 업로드 진행 상황 스냅샷.
/// "장 단위" — 한 이미지의 원본·썸네일이 모두 올라간 경우에만 `completedImageCount` 에 카운트.
///
/// UI 는 nil 일 때 표시를 숨기고, 값이 있을 때 "X장 / Y장" 형태로 보여준다.
public struct UploadProgressSnapshot: Equatable, Sendable {
    public let completedImageCount: Int
    public let totalImageCount: Int

    public init(completedImageCount: Int, totalImageCount: Int) {
        self.completedImageCount = completedImageCount
        self.totalImageCount = totalImageCount
    }
}
