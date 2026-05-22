import XCTest
import CoreData
import Domain
@testable import Data

/// `LegacyStoreMigrator`가 레거시 store를 익명 store로 1회 멱등하게 이전하는지 검증.
final class LegacyStoreMigratorTests: XCTestCase {

    private var tempDir: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LegacyStoreMigratorTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        suiteName = "LegacyStoreMigratorTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: tempDir)
    }

    func test_레거시가_있으면_익명_store로_이전되고_데이터가_보존된다() async throws {
        let legacyURL = tempDir.appendingPathComponent("NoteCardCoreData.sqlite")
        let anonymousURL = tempDir.appendingPathComponent("anonymous.sqlite")
        try await createStore(memoCount: 1, at: legacyURL)

        LegacyStoreMigrator.migrateIfNeeded(
            legacyStoreURL: legacyURL,
            anonymousStoreURL: anonymousURL,
            userDefaults: defaults
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: anonymousURL.path))
        let count = try await memoCount(at: anonymousURL)
        XCTAssertEqual(count, 1)
        XCTAssertTrue(defaults.bool(forKey: LegacyStoreMigrator.migrationFlagKey))
    }

    func test_레거시가_없으면_익명_store를_만들지_않고_플래그만_설정한다() {
        let legacyURL = tempDir.appendingPathComponent("NoteCardCoreData.sqlite") // 존재하지 않음
        let anonymousURL = tempDir.appendingPathComponent("anonymous.sqlite")

        LegacyStoreMigrator.migrateIfNeeded(
            legacyStoreURL: legacyURL,
            anonymousStoreURL: anonymousURL,
            userDefaults: defaults
        )

        XCTAssertFalse(FileManager.default.fileExists(atPath: anonymousURL.path))
        XCTAssertTrue(defaults.bool(forKey: LegacyStoreMigrator.migrationFlagKey))
    }

    func test_이미_마이그레이션됐으면_재실행해도_익명_데이터를_덮어쓰지_않는다() async throws {
        let anonymousURL = tempDir.appendingPathComponent("anonymous.sqlite")

        // 1차: 메모 1개짜리 레거시 이전
        let legacy1 = tempDir.appendingPathComponent("NoteCardCoreData.sqlite")
        try await createStore(memoCount: 1, at: legacy1)
        LegacyStoreMigrator.migrateIfNeeded(legacyStoreURL: legacy1, anonymousStoreURL: anonymousURL, userDefaults: defaults)

        // 2차: 메모 2개짜리 새 레거시로 재실행 — 플래그가 set이라 무시돼야 함
        let legacy2 = tempDir.appendingPathComponent("legacy2.sqlite")
        try await createStore(memoCount: 2, at: legacy2)
        LegacyStoreMigrator.migrateIfNeeded(legacyStoreURL: legacy2, anonymousStoreURL: anonymousURL, userDefaults: defaults)

        // 익명에는 여전히 1개 (legacy2의 2개로 덮이지 않음)
        let count = try await memoCount(at: anonymousURL)
        XCTAssertEqual(count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: legacy2.path), "재실행이 무시되었으므로 legacy2는 destroy되지 않아야 한다.")
    }

    // MARK: - Helpers

    private func createStore(memoCount: Int, at url: URL) async throws {
        let stack = CoreDataStack(storeURL: url)
        let repo = MemoRepositoryImpl(stack: stack)
        for _ in 0..<memoCount {
            _ = try await repo.createNewMemo()
        }
    }

    private func memoCount(at url: URL) async throws -> Int {
        let stack = CoreDataStack(storeURL: url)
        let repo = MemoRepositoryImpl(stack: stack)
        return try await repo.getAllMemos().count
    }
}
