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
        userDefaults: UserDefaults = .standard
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
            try? coordinator.destroyPersistentStore(at: legacyURL, type: .sqlite, options: nil)
        } catch {
            // 실패 시 플래그를 세우지 않아 다음 실행에 재시도한다. 원본은 레거시 store에 그대로 남는다.
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
