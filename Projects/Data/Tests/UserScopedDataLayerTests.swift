import XCTest
import Combine
import Domain
@testable import Data

/// `UserScopedDataLayer`가 사용자 변경에 맞춰 stack을 교체하고
/// 사용자별 파일 격리가 보장되는지 검증.
final class UserScopedDataLayerTests: XCTestCase {

    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("UserScopedDataLayerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func test_익명_상태로_시작하면_anonymous_sqlite_파일이_생성된다() {
        // given
        let provider = MockUserIDProvider(initial: nil)
        let layer = UserScopedDataLayer(userIDProvider: provider, storeDirectory: tempDirectory)

        // when
        _ = layer.currentStack.backgroundContext  // lazy 컨테이너 트리거

        // then
        let expectedURL = tempDirectory.appendingPathComponent("anonymous.sqlite")
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedURL.path))
    }

    func test_사용자_ID가_세팅되면_users_uid_경로의_새_stack을_emit한다() {
        // given
        let provider = MockUserIDProvider(initial: nil)
        let layer = UserScopedDataLayer(userIDProvider: provider, storeDirectory: tempDirectory)
        let initialStack = layer.currentStack

        var receivedStacks: [CoreDataStack] = []
        let cancellable = layer.currentStackPublisher
            .dropFirst()  // 구독 시점의 초기 emit은 제외
            .sink { receivedStacks.append($0) }
        defer { cancellable.cancel() }

        // when
        provider.setUserID("userA")

        // then
        XCTAssertEqual(receivedStacks.count, 1)
        XCTAssertFalse(receivedStacks.first === initialStack, "사용자 변경 시 새 stack 인스턴스로 교체돼야 한다.")

        _ = layer.currentStack.backgroundContext
        let expectedURL = tempDirectory
            .appendingPathComponent("users")
            .appendingPathComponent("userA")
            .appendingPathComponent("NoteCard.sqlite")
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedURL.path))
    }

    func test_같은_사용자_ID가_재emit돼도_stack은_교체되지_않는다() {
        // given
        let provider = MockUserIDProvider(initial: "userA")
        let layer = UserScopedDataLayer(userIDProvider: provider, storeDirectory: tempDirectory)
        let initialStack = layer.currentStack

        var changeCount = 0
        let cancellable = layer.currentStackPublisher
            .dropFirst()
            .sink { _ in changeCount += 1 }
        defer { cancellable.cancel() }

        // when: 같은 ID로 다시 emit
        provider.setUserID("userA")

        // then
        XCTAssertEqual(changeCount, 0, "같은 사용자 ID로는 재emit하지 않아야 한다.")
        XCTAssertTrue(layer.currentStack === initialStack)
    }

    func test_서로_다른_사용자의_stack은_데이터가_격리된다() async throws {
        // given
        let provider = MockUserIDProvider(initial: "userA")
        let layer = UserScopedDataLayer(userIDProvider: provider, storeDirectory: tempDirectory)
        let repoA = MemoRepositoryImpl(stack: layer.currentStack)
        _ = try await repoA.createNewMemo()
        let inA = try await repoA.getAllMemos()
        XCTAssertEqual(inA.count, 1)

        // when: 다른 사용자로 전환
        provider.setUserID("userB")
        let repoB = MemoRepositoryImpl(stack: layer.currentStack)

        // then
        let inB = try await repoB.getAllMemos()
        XCTAssertTrue(inB.isEmpty, "다른 사용자에는 userA의 메모가 보이면 안 된다.")
    }
}

// MARK: - Test Doubles

private final class MockUserIDProvider: CurrentUserIDProvider, @unchecked Sendable {

    private let subject: CurrentValueSubject<String?, Never>

    init(initial: String?) {
        self.subject = CurrentValueSubject(initial)
    }

    var currentUserID: String? { subject.value }

    var currentUserIDPublisher: AnyPublisher<String?, Never> {
        subject.eraseToAnyPublisher()
    }

    func setUserID(_ id: String?) {
        subject.send(id)
    }
}
