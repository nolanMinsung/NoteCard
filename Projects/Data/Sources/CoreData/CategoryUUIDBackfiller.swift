//
//  CategoryUUIDBackfiller.swift
//  NoteCard
//

import CoreData
import Foundation

/// v2 → v3 마이그레이션 후 `CategoryEntity.categoryID`가 nil인 row를 찾아 새 UUID를 부여한다.
///
/// Core Data lightweight migration은 attribute 추가까지만 처리하고 row별 다른 값을 채우진 못해서
/// (UUID Default Value는 단일 값만 가능) 코드 수준의 backfill이 필요. 앱 시작 시 1회 실행하면
/// 이후엔 `categoryID`가 항상 non-nil 상태가 보장된다.
public enum CategoryUUIDBackfiller {

    public static func backfill(in stack: CoreDataStack, onError: (Error) -> Void = { _ in }) {
        let context = stack.backgroundContext
        context.performAndWait {
            do {
                let request = CategoryEntity.fetchRequest()
                request.predicate = NSPredicate(format: "categoryID == nil")
                let pending = try context.fetch(request)
                guard !pending.isEmpty else { return }
                for entity in pending {
                    entity.categoryID = UUID()
                }
                try context.save()
            } catch {
                onError(error)
            }
        }
    }
}
