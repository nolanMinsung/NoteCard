//
//  AnonymousToUserMigrator.swift
//  NoteCard
//

import CoreData
import Foundation

/// 사용자가 처음 로그인할 때 익명 store(`anonymous.sqlite`)의 내용을 사용자 store(`users/<uid>/NoteCard.sqlite`)로 1회 이전한다.
/// `UserScopedDataLayer`가 stack을 교체하는 과정에서 호출한다.
///
/// 이전은 두 단계로 나뉜다. 익명 store를 연 stack이 살아 있는 동안 파일을 삭제하면 sqlite 무결성이
/// 깨지므로(`vnode unlinked while in use`), 복사와 정리를 분리해 호출자가 그 사이에 stack을 닫게 한다:
/// 1. `copyIfNeeded` — 익명 → 사용자 store 복사 (삭제하지 않음)
/// 2. (호출자가 익명 store를 연 stack을 닫음)
/// 3. `cleanUpAnonymousStore` — 익명 store 파일 정리
///
/// 정책:
/// - 익명 store에 파일이 없으면 복사 안 함.
/// - 사용자 store가 *이미 존재*하면 복사 안 함 (sync 작업 단계에서 클라우드 데이터와 합쳐질 책임. 이번 단계 범위 밖).
public enum AnonymousToUserMigrator {

    /// 익명 store를 사용자 store로 복사한다. 익명 store는 삭제하지 않는다(정리는 `cleanUpAnonymousStore`).
    /// - Returns: 복사를 수행했으면 `true`(이후 정리 대상), 조건 미충족·실패로 skip하면 `false`.
    @discardableResult
    public static func copyIfNeeded(
        anonymousStoreURL: URL,
        userStoreURL: URL,
        onError: (Error) -> Void = { _ in }
    ) -> Bool {
        guard FileManager.default.fileExists(atPath: anonymousStoreURL.path) else { return false }
        guard !FileManager.default.fileExists(atPath: userStoreURL.path) else { return false }

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
            return true
        } catch {
            onError(error)
            return false
        }
    }

    /// 익명 store를 비운다 — 다음 익명 사용을 위해 깨끗한 상태로 둠.
    /// `copyIfNeeded` 성공 후, 익명 store를 연 stack이 닫힌 뒤에 호출해야 한다.
    /// `destroyPersistentStore`만으로는 잔여 파일이 남는 경우가 있어 `-wal`/`-shm`까지 명시적으로 제거.
    public static func cleanUpAnonymousStore(at anonymousStoreURL: URL) {
        let coordinator = try? makeCoordinator()
        try? coordinator?.destroyPersistentStore(at: anonymousStoreURL, type: .sqlite, options: nil)
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(atPath: anonymousStoreURL.path + suffix)
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
