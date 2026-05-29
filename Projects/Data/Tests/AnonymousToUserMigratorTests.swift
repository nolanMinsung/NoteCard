import XCTest
import CoreData
import Domain
@testable import Data

/// `AnonymousToUserMigrator`의 복사(`copyIfNeeded`)·정리(`cleanUpAnonymousStore`)를 검증.
final class AnonymousToUserMigratorTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("AnonymousToUserMigratorTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func test_익명_store가_있고_사용자_store가_없으면_복사된다() async throws {
        let anonURL = tempDir.appendingPathComponent("anonymous.sqlite")
        let userURL = tempDir.appendingPathComponent("users/uid123/NoteCard.sqlite")
        try await createStore(memoCount: 2, at: anonURL)

        let didCopy = AnonymousToUserMigrator.copyIfNeeded(
            anonymousStoreURL: anonURL,
            userStoreURL: userURL
        )

        XCTAssertTrue(didCopy)
        XCTAssertTrue(FileManager.default.fileExists(atPath: userURL.path))
        let count = try await memoCount(at: userURL)
        XCTAssertEqual(count, 2)
    }

    func test_익명_store가_없으면_복사하지_않는다() {
        let anonURL = tempDir.appendingPathComponent("anonymous.sqlite") // 존재하지 않음
        let userURL = tempDir.appendingPathComponent("users/uid123/NoteCard.sqlite")

        let didCopy = AnonymousToUserMigrator.copyIfNeeded(
            anonymousStoreURL: anonURL,
            userStoreURL: userURL
        )

        XCTAssertFalse(didCopy)
        XCTAssertFalse(FileManager.default.fileExists(atPath: userURL.path))
    }

    func test_사용자_store가_이미_있으면_익명이_있어도_복사하지_않는다() async throws {
        let anonURL = tempDir.appendingPathComponent("anonymous.sqlite")
        let userURL = tempDir.appendingPathComponent("users/uid123/NoteCard.sqlite")
        try await createStore(memoCount: 5, at: userURL)
        try await createStore(memoCount: 2, at: anonURL)

        let didCopy = AnonymousToUserMigrator.copyIfNeeded(
            anonymousStoreURL: anonURL,
            userStoreURL: userURL
        )

        XCTAssertFalse(didCopy)
        // 사용자 store는 원래 5개 그대로
        let count = try await memoCount(at: userURL)
        XCTAssertEqual(count, 5)
        // 익명 store도 그대로 (복사 skip이라 정리 안 함)
        XCTAssertTrue(FileManager.default.fileExists(atPath: anonURL.path))
    }

    func test_복사_후_cleanUp하면_익명_store_파일들이_삭제된다() async throws {
        let anonURL = tempDir.appendingPathComponent("anonymous.sqlite")
        let userURL = tempDir.appendingPathComponent("users/uid123/NoteCard.sqlite")
        try await createStore(memoCount: 1, at: anonURL)

        let didCopy = AnonymousToUserMigrator.copyIfNeeded(
            anonymousStoreURL: anonURL,
            userStoreURL: userURL
        )
        XCTAssertTrue(didCopy)

        AnonymousToUserMigrator.cleanUpAnonymousStore(at: anonURL)

        XCTAssertFalse(FileManager.default.fileExists(atPath: anonURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: anonURL.path + "-wal"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: anonURL.path + "-shm"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: userURL.path))
    }

    func test_복사_실패시_익명이_보존되고_사용자_store는_안_만들어진다() async throws {
        let anonURL = tempDir.appendingPathComponent("anonymous.sqlite")
        try await createStore(memoCount: 1, at: anonURL)

        // 목적지 부모 경로 중간에 파일을 끼워 디렉터리 생성을 불가능하게 만들어 실패시킨다.
        let fileBlocker = tempDir.appendingPathComponent("notadir")
        try Data().write(to: fileBlocker)
        let userURL = fileBlocker.appendingPathComponent("sub").appendingPathComponent("NoteCard.sqlite")

        var capturedError: Error?
        let didCopy = AnonymousToUserMigrator.copyIfNeeded(
            anonymousStoreURL: anonURL,
            userStoreURL: userURL,
            onError: { capturedError = $0 }
        )

        XCTAssertFalse(didCopy)
        XCTAssertNotNil(capturedError, "실패 시 onError로 에러가 전달되어야 한다.")
        XCTAssertFalse(FileManager.default.fileExists(atPath: userURL.path), "실패 시 사용자 store를 만들면 안 된다.")
        XCTAssertTrue(FileManager.default.fileExists(atPath: anonURL.path), "실패 시 익명 원본은 보존돼야 한다.")
    }

    // MARK: - Helpers

    private func createStore(memoCount: Int, at url: URL) async throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let stack = CoreDataStack(storeURL: url)
        let repo = MemoRepositoryImpl(stack: stack)
        for _ in 0..<memoCount {
            _ = try await repo.createNewMemo()
        }
        // 프로덕션에선 정리(cleanUp) 전에 UserScopedDataLayer가 익명 stack을 닫는다. 테스트도 동일하게 닫아준다.
        stack.close()
    }

    private func memoCount(at url: URL) async throws -> Int {
        let stack = CoreDataStack(storeURL: url)
        let repo = MemoRepositoryImpl(stack: stack)
        return try await repo.getAllMemos().count
    }
}
