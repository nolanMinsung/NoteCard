//
//  AnonymousMigrationCleanupCoordinator.swift
//  NoteCard
//

import Combine
import CoreData
import Data
import Foundation

/// Memo / Category / Image Router 의 첫 로그인 마이그레이션이 모두 완료되면 익명 Core Data 의 모든 entity 를
/// 일괄 삭제. Documents 의 이미지 파일은 캐시로 유지 — 사인인 후 같은 UUID 로 Firestore impl 의 이미지 로드
/// 캐시 hit 을 제공.
public final class AnonymousMigrationCleanupCoordinator: @unchecked Sendable {

    private let coreDataStack: CoreDataStack
    private let lock = NSLock()
    private var cleanupInProgress: Set<String> = []

    private let cleanupCompletedSubject = PassthroughSubject<String, Never>()
    /// cleanup 이 완료된 (혹은 이미 완료돼있던) 사용자의 userID 를 emit. UI 가 spinner 종료 트리거로 사용.
    public var cleanupCompletedPublisher: AnyPublisher<String, Never> {
        cleanupCompletedSubject.eraseToAnyPublisher()
    }

    public init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }

    public func reportMigrationCompleted(userID: String) async {
        guard allMigrationsCompleted(for: userID) else { return }
        let cleanupMarker = Self.cleanupMarkerKey(for: userID)

        enum Decision { case skipAlreadyDone, skipAlreadyRunning, proceed }
        let decision: Decision = lock.withLock {
            if UserDefaults.standard.bool(forKey: cleanupMarker) {
                return .skipAlreadyDone
            }
            if cleanupInProgress.contains(userID) {
                return .skipAlreadyRunning
            }
            cleanupInProgress.insert(userID)
            return .proceed
        }

        switch decision {
        case .skipAlreadyDone:
            cleanupCompletedSubject.send(userID)
            return
        case .skipAlreadyRunning:
            return
        case .proceed:
            break
        }

        await performCleanup()
        UserDefaults.standard.set(true, forKey: cleanupMarker)
        lock.withLock { _ = cleanupInProgress.remove(userID) }
        cleanupCompletedSubject.send(userID)
    }

    private func allMigrationsCompleted(for userID: String) -> Bool {
        ["Memo", "Category", "Image"].allSatisfy { domain in
            UserDefaults.standard.bool(forKey: "sync.anonymousToFirestore\(domain)Migration.\(userID)")
        }
    }

    private static func cleanupMarkerKey(for userID: String) -> String {
        "sync.anonymousMigrationCleanup.\(userID)"
    }

    /// Core Data 의 Memo / Category / Image entity 를 일괄 삭제.
    /// Documents 폴더의 이미지 파일은 의도적으로 보존 — 사인인 후 Firestore impl 의 캐시로 활용.
    /// NSBatchDeleteRequest 가 many-to-many 의 join table 정리 / Nullify rule 실행을 못 해서 fetch + context.delete 사용.
    private func performCleanup() async {
        let context = coreDataStack.backgroundContext
        await context.perform {
            for entityName in ["ImageEntity", "MemoEntity", "CategoryEntity"] {
                let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
                if let objects = try? context.fetch(request) {
                    for object in objects {
                        context.delete(object)
                    }
                }
            }
            try? context.save()
        }
    }
}
