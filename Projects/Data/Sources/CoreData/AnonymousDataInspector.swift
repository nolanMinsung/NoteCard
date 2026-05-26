//
//  AnonymousDataInspector.swift
//  NoteCard
//

import CoreData
import Foundation

/// 현재 stack(주로 익명 stack)에 사용자 데이터가 존재하는지 동기로 확인하는 진단 helper.
///
/// SceneDelegate가 신규/기존 사용자를 분기할 때 사용. async API 없이 즉시 결과가 필요한
/// composition-root 시점의 한정된 용도. 일반 데이터 조회는 `MemoRepository`를 거친다.
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
}
