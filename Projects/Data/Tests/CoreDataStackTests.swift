import XCTest
import Domain
@testable import Data

/// `CoreDataStack`의 `storeURL` 파라미터가 기대대로 동작하는지 검증.
/// 사용자별 store 파일 분리(다중 Apple ID 격리)를 위한 기반.
final class CoreDataStackTests: XCTestCase {

    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoreDataStackTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func test_storeURL_지정시_해당_위치에_SQLite_파일이_생성된다() async throws {
        // given
        let url = tempDirectory.appendingPathComponent("Custom.sqlite")
        let stack = CoreDataStack(storeURL: url)

        // when: lazy 컨테이너 로드 트리거
        _ = stack.backgroundContext

        // then
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: url.path),
            "SQLite 파일이 \(url.path)에 생성돼야 한다."
        )
    }

    func test_서로_다른_storeURL의_두_stack은_데이터가_격리된다() async throws {
        // given: 같은 모델·같은 프로세스에서 두 개의 stack을 다른 URL로
        let urlA = tempDirectory.appendingPathComponent("UserA.sqlite")
        let urlB = tempDirectory.appendingPathComponent("UserB.sqlite")
        let stackA = CoreDataStack(storeURL: urlA)
        let stackB = CoreDataStack(storeURL: urlB)
        let repoA = MemoRepositoryImpl(stack: stackA)
        let repoB = MemoRepositoryImpl(stack: stackB)

        // when: A에만 메모 생성
        _ = try await repoA.createNewMemo()

        // then: A에는 1개, B에는 0개
        let inA = try await repoA.getAllMemos()
        let inB = try await repoB.getAllMemos()
        XCTAssertEqual(inA.count, 1)
        XCTAssertTrue(inB.isEmpty, "다른 stack에는 A의 메모가 보이면 안 된다.")
    }
}
