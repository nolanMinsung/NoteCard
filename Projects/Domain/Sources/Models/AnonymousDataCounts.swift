//
//  AnonymousDataCounts.swift
//  NoteCard
//

import Foundation

/// 익명 stack 의 entity 별 row 수 스냅샷. 분석 이벤트 `anonymous_data_stats` 와
/// `AnonymousDataInspector.snapshotCounts` 가 공통으로 사용. 메모 컨텐츠·이미지 파일은
/// 절대 수집하지 않고 카운트만.
public struct AnonymousDataCounts: Sendable, Equatable {
    public let memoCount: Int
    public let trashedMemoCount: Int
    public let categoryCount: Int
    public let imageCount: Int

    public init(memoCount: Int, trashedMemoCount: Int, categoryCount: Int, imageCount: Int) {
        self.memoCount = memoCount
        self.trashedMemoCount = trashedMemoCount
        self.categoryCount = categoryCount
        self.imageCount = imageCount
    }
}
