//
//  LegacyStoreMigrator.swift
//  NoteCard
//

import CoreData
import Foundation

/// 레거시 기본 위치의 store를 익명 store(`anonymous.sqlite`)로 1회 멱등 이전한다.
/// 데이터 레이어가 익명 store를 열기 전에 호출해야 한다.
public enum LegacyStoreMigrator {

    static let migrationFlagKey = "didMigrateLegacyStoreToAnonymous"

    public static func migrateIfNeeded(
        legacyStoreURL: URL? = nil,
        anonymousStoreURL: URL,
        userDefaults: UserDefaults = .standard,
        onError: (Error) -> Void = { _ in }
    ) {
        guard !userDefaults.bool(forKey: migrationFlagKey) else { return }

        let legacyURL = legacyStoreURL ?? defaultLegacyStoreURL()
        guard FileManager.default.fileExists(atPath: legacyURL.path) else {
            userDefaults.set(true, forKey: migrationFlagKey)
            return
        }

        do {
            let coordinator = try makeCoordinator()
            try FileManager.default.createDirectory(
                at: anonymousStoreURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try coordinator.replacePersistentStore(
                at: anonymousStoreURL,
                destinationOptions: nil,
                withPersistentStoreFrom: legacyURL,
                sourceOptions: nil,
                type: .sqlite
            )
            userDefaults.set(true, forKey: migrationFlagKey)
            // destroy로 store를 정상 해제한 뒤, 잔여 파일(.sqlite/-wal/-shm)을 명시적으로 삭제.
            // destroyPersistentStore만으로는 파일이 남는 경우가 있어 직접 제거한다.
            try? coordinator.destroyPersistentStore(at: legacyURL, type: .sqlite, options: nil)
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(atPath: legacyURL.path + suffix)
            }
        } catch {
            // 플래그 미설정 상태로 두어 다음 실행에 재시도. 원본은 레거시 store에 그대로 남는다.
            onError(error)
        }
    }

    private static func defaultLegacyStoreURL() -> URL {
        NSPersistentContainer.defaultDirectoryURL()
            .appendingPathComponent("NoteCardCoreData.sqlite")
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
