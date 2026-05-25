//
//  AnonymousToUserMigrator.swift
//  NoteCard
//

import CoreData
import Foundation

/// 사용자가 처음 로그인할 때 익명 store(`anonymous.sqlite`)의 내용을 사용자 store(`users/<uid>/NoteCard.sqlite`)로 1회 이전한다.
/// `UserScopedDataLayer`가 stack을 교체하기 직전에 호출한다.
///
/// 정책:
/// - 익명 store에 파일이 없으면 no-op.
/// - 사용자 store가 *이미 존재*하면 no-op (sync 작업 단계에서 클라우드 데이터와 합쳐질 책임. 이번 단계 범위 밖).
/// - target이 비어 있을 때만 `replacePersistentStore`로 단순 이전. 성공 시 익명 store는 비움.
public enum AnonymousToUserMigrator {

    public static func migrateIfNeeded(
        anonymousStoreURL: URL,
        userStoreURL: URL,
        onError: (Error) -> Void = { _ in }
    ) {
        guard FileManager.default.fileExists(atPath: anonymousStoreURL.path) else { return }
        guard !FileManager.default.fileExists(atPath: userStoreURL.path) else { return }

        do {
            let coordinator = try makeCoordinator()
            try FileManager.default.createDirectory(
                at: userStoreURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try coordinator.replacePersistentStore(
                at: userStoreURL,
                destinationOptions: nil,
                withPersistentStoreFrom: anonymousStoreURL,
                sourceOptions: nil,
                type: .sqlite
            )
            // 익명 store는 비움 — 다음 익명 사용을 위해 깨끗한 상태로 둠.
            // destroyPersistentStore만으로는 잔여 파일이 남는 경우가 있어 명시적으로 제거.
            try? coordinator.destroyPersistentStore(at: anonymousStoreURL, type: .sqlite, options: nil)
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(atPath: anonymousStoreURL.path + suffix)
            }
        } catch {
            onError(error)
        }
    }

    private static func makeCoordinator() throws -> NSPersistentStoreCoordinator {
        guard
            let modelURL = DataResources.bundle.url(forResource: "NoteCardCoreData", withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelURL)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return NSPersistentStoreCoordinator(managedObjectModel: model)
    }
}
