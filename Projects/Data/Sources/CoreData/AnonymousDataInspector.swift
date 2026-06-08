//
//  AnonymousDataInspector.swift
//  NoteCard
//

import CoreData
import Domain
import Foundation

/// 현재 stack(주로 익명 stack)의 데이터 규모·존재 여부를 동기로 확인하는 진단 helper.
///
/// SceneDelegate 의 신규/기존 사용자 분기와 분석 통계 (`anonymous_data_stats`) 가 주요 용도.
/// async API 없이 즉시 결과가 필요한 composition-root / 짧은 분석 호출에 한정.
/// 일반 데이터 조회는 `MemoRepository` 를 거친다.
public enum AnonymousDataInspector {

    /// stack에 메모 또는 카테고리가 1개 이상 존재하는지 반환. 에러 발생 시 안전하게 `false`.
    ///
    /// 신규 설치자는 둘 다 0개로 시작하므로, 어느 한쪽이라도 존재 = 사용자가 앱을 써본 적 있음.
    /// 메모를 모두 지우고 카테고리만 남긴 사용자도 기존 사용자로 분류된다.
    public static func hasUserData(in stack: CoreDataStack) -> Bool {
        let context = stack.backgroundContext
        var has = false
        context.performAndWait {
            let memoRequest = MemoEntity.fetchRequest()
            memoRequest.fetchLimit = 1
            if ((try? context.count(for: memoRequest)) ?? 0) > 0 {
                has = true
                return
            }
            let categoryRequest = CategoryEntity.fetchRequest()
            categoryRequest.fetchLimit = 1
            has = ((try? context.count(for: categoryRequest)) ?? 0) > 0
        }
        return has
    }

    /// stack 의 entity 별 row 수를 한 번의 perform 블록에서 모아 반환. 에러 발생 시 해당
    /// 항목만 0 으로 안전 처리. 분석 통계에 보낼 익명 데이터 규모 측정 등에 사용.
    public static func snapshotCounts(in stack: CoreDataStack) -> AnonymousDataCounts {
        let context = stack.backgroundContext
        var memoCount = 0
        var trashedMemoCount = 0
        var categoryCount = 0
        var imageCount = 0
        context.performAndWait {
            let activeRequest = MemoEntity.fetchRequest()
            activeRequest.predicate = NSPredicate(format: "isInTrash == false")
            memoCount = (try? context.count(for: activeRequest)) ?? 0

            let trashedRequest = MemoEntity.fetchRequest()
            trashedRequest.predicate = NSPredicate(format: "isInTrash == true")
            trashedMemoCount = (try? context.count(for: trashedRequest)) ?? 0

            let categoryRequest = CategoryEntity.fetchRequest()
            categoryCount = (try? context.count(for: categoryRequest)) ?? 0

            let imageRequest = ImageEntity.fetchRequest()
            imageCount = (try? context.count(for: imageRequest)) ?? 0
        }
        return AnonymousDataCounts(
            memoCount: memoCount,
            trashedMemoCount: trashedMemoCount,
            categoryCount: categoryCount,
            imageCount: imageCount
        )
    }
}

