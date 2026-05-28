import Combine
import XCTest
import Domain
import SyncInterface
@testable import SyncImpl

/// `FirestoreSyncService`의 status 전이와 메모 push 결합을 검증한다.
/// Firestore 네트워크에는 접근하지 않으며, 원격 쓰기는 `MockMemoRemoteWriter`로 대체한다.
final class FirestoreSyncServiceTests: XCTestCase {

    private var auth: MockAuthService!
    private var memoRepository: MockMemoRepository!
    private var writer: MockMemoRemoteWriter!
    private var sut: FirestoreSyncService!

    override func setUp() {
        super.setUp()
        auth = MockAuthService()
        memoRepository = MockMemoRepository()
        writer = MockMemoRemoteWriter()
        sut = FirestoreSyncService(authService: auth, memoRepository: memoRepository, memoWriter: writer)
    }

    override func tearDown() {
        sut = nil
        writer = nil
        memoRepository = nil
        auth = nil
        super.tearDown()
    }

    // MARK: - status 전이

    func test_초기_status는_disconnected이다() {
        XCTAssertEqual(sut.currentStatus, .disconnected)
    }

    func test_인증된_사용자가_있는_상태에서_start하면_upToDate가_된다() async {
        // given
        auth.emit(.sample)

        // when
        await sut.start()

        // then
        XCTAssertEqual(sut.currentStatus, .upToDate)
    }

    func test_인증되지_않은_상태에서_start하면_disconnected_유지() async {
        // given: auth는 초기값 nil

        // when
        await sut.start()

        // then
        XCTAssertEqual(sut.currentStatus, .disconnected)
    }

    func test_start_후_로그인하면_upToDate로_전이된다() async {
        // given
        await sut.start()
        XCTAssertEqual(sut.currentStatus, .disconnected)

        // when
        auth.emit(.sample)

        // then
        XCTAssertEqual(sut.currentStatus, .upToDate)
    }

    func test_start_후_로그아웃하면_disconnected로_전이된다() async {
        // given
        auth.emit(.sample)
        await sut.start()
        XCTAssertEqual(sut.currentStatus, .upToDate)

        // when
        auth.emit(nil)

        // then
        XCTAssertEqual(sut.currentStatus, .disconnected)
    }

    func test_stop은_disconnected로_전이하고_이후_인증_변경에_반응하지_않는다() async {
        // given
        auth.emit(.sample)
        await sut.start()
        XCTAssertEqual(sut.currentStatus, .upToDate)

        // when
        await sut.stop()

        // then
        XCTAssertEqual(sut.currentStatus, .disconnected)

        // and: stop 이후 인증 이벤트는 무시된다
        auth.emit(.sample)
        XCTAssertEqual(sut.currentStatus, .disconnected)
    }

    func test_start는_idempotent하다() async {
        // given
        auth.emit(.sample)
        await sut.start()

        // when: 한 번 더 호출해도 추가 구독이 생기지 않는다
        await sut.start()

        // then
        XCTAssertEqual(sut.currentStatus, .upToDate)
    }

    func test_statusPublisher는_변경마다_값을_방출한다() async {
        // given
        var received: [SyncStatus] = []
        let cancellable = sut.statusPublisher.sink { received.append($0) }
        defer { cancellable.cancel() }

        // when
        await sut.start()        // .disconnected (초기 emit)
        auth.emit(.sample)       // .upToDate
        auth.emit(nil)           // .disconnected
        await sut.stop()         // .disconnected (중복)

        // then
        XCTAssertEqual(received.first, .disconnected)
        XCTAssertTrue(received.contains(.upToDate))
        XCTAssertEqual(received.last, .disconnected)
    }

    // MARK: - 메모 push 결합

    func test_업데이트_이벤트가_오면_해당_메모를_upsert한다() async {
        // given
        auth.emit(.sample)
        await sut.start()
        let id = UUID()
        memoRepository.stubMemo = Self.makeMemo(id: id)
        let exp = expectation(description: "upsert 호출")
        writer.onUpsert = { _ in exp.fulfill() }

        // when
        memoRepository.emit(.update(content: .titleText(memoIDs: [id])))

        // then
        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(writer.upsertedMemoIDs, [id])
        XCTAssertEqual(writer.lastUserID, "test-uid")
    }

    func test_삭제_이벤트가_오면_해당_메모를_delete한다() async {
        // given
        auth.emit(.sample)
        await sut.start()
        let id = UUID()
        let exp = expectation(description: "delete 호출")
        writer.onDelete = { _ in exp.fulfill() }

        // when
        memoRepository.emit(.delete(memoIDs: [id]))

        // then
        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(writer.deletedMemoIDs, [id])
        XCTAssertTrue(writer.upsertedMemoIDs.isEmpty)
    }

    func test_로그아웃_상태에서는_push하지_않는다() async {
        // given: 인증되지 않은 상태
        await sut.start()

        // when: 메모 이벤트가 와도
        memoRepository.emit(.update(content: .titleText(memoIDs: [UUID()])))
        try? await Task.sleep(nanoseconds: 200_000_000)

        // then: userID가 없어 push하지 않는다
        XCTAssertTrue(writer.upsertedMemoIDs.isEmpty)
        XCTAssertTrue(writer.deletedMemoIDs.isEmpty)
    }

    // MARK: - 헬퍼

    private static func makeMemo(id: UUID) -> Memo {
        Memo(
            memoID: id,
            creationDate: .now,
            modificationDate: .now,
            deletedDate: nil,
            isFavorite: false,
            isInTrash: false,
            memoText: "",
            memoTitle: "",
            categories: [],
            images: []
        )
    }
}

// MARK: - Mocks

private final class MockAuthService: AuthService, @unchecked Sendable {

    private let subject = CurrentValueSubject<AuthUser?, Never>(nil)

    var currentUser: AuthUser? { subject.value }
    var authStatePublisher: AnyPublisher<AuthUser?, Never> { subject.eraseToAnyPublisher() }

    func signInWithApple() async throws -> AuthUser { fatalError("not used in tests") }
    func signOut() async throws {}
    func deleteAccount() async throws {}

    func emit(_ user: AuthUser?) { subject.send(user) }
}

private final class MockMemoRemoteWriter: MemoRemoteWriting, @unchecked Sendable {

    private(set) var upsertedMemoIDs: [UUID] = []
    private(set) var deletedMemoIDs: [UUID] = []
    private(set) var lastUserID: String?
    var onUpsert: ((UUID) -> Void)?
    var onDelete: ((UUID) -> Void)?

    func upsert(_ memo: Memo, userID: String) async throws {
        upsertedMemoIDs.append(memo.memoID)
        lastUserID = userID
        onUpsert?(memo.memoID)
    }

    func delete(memoID: UUID, userID: String) async throws {
        deletedMemoIDs.append(memoID)
        lastUserID = userID
        onDelete?(memoID)
    }
}

/// `memoUpdatedPublisher`와 `getMemoIncludingTrash`만 실제로 동작하는 최소 구현.
/// 나머지 메서드는 본 테스트에서 호출되지 않으므로 미구현.
private final class MockMemoRepository: MemoRepository, @unchecked Sendable {

    private let subject = PassthroughSubject<MemoUpdateType, Never>()
    var stubMemo: Memo?

    var memoUpdatedPublisher: AnyPublisher<MemoUpdateType, Never> { subject.eraseToAnyPublisher() }

    func emit(_ event: MemoUpdateType) { subject.send(event) }

    struct StubMemoNotFound: Error {}

    func getMemoIncludingTrash(id: UUID) async throws -> Memo {
        guard let stubMemo else { throw StubMemoNotFound() }
        return stubMemo
    }

    // 이하 본 테스트에서 미사용
    func createNewMemo() async throws -> Memo { fatalError("not used") }
    func getMemo(id: UUID) async throws -> Memo { fatalError("not used") }
    func getAllMemos() async throws -> [Memo] { fatalError("not used") }
    func getAllMemos(inCategory category: Domain.Category?) async throws -> [Memo] { fatalError("not used") }
    func getAllMemosInTrash() async throws -> [Memo] { fatalError("not used") }
    func searchMemo(searchText: String, inCategory category: Domain.Category?) async throws -> [Memo] { fatalError("not used") }
    func getFavoriteMemos() async throws -> [Memo] { fatalError("not used") }
    func moveToTrash(_ memo: Memo) async throws { fatalError("not used") }
    func moveToTrash(_ memos: [Memo]) async throws { fatalError("not used") }
    func deleteMemo(_ memo: Memo) async throws { fatalError("not used") }
    func deleteMemos(_ memos: [Memo]) async throws { fatalError("not used") }
    func restore(_ memo: Memo) async throws { fatalError("not used") }
    func restore(_ memos: [Memo]) async throws { fatalError("not used") }
    func replaceCategories(to: Memo, newCategories: Set<Domain.Category>) async throws { fatalError("not used") }
    func replaceCategories(to: [Memo], newCategories: Set<Domain.Category>) async throws { fatalError("not used") }
    func addCategories(to: Memo, newCategories: Set<Domain.Category>) async throws { fatalError("not used") }
    func addCategories(to: [Memo], newCategories: Set<Domain.Category>) async throws { fatalError("not used") }
    func removeCategories(to: Memo, newCategories: Set<Domain.Category>) async throws { fatalError("not used") }
    func removeCategories(to: [Memo], newCategories: Set<Domain.Category>) async throws { fatalError("not used") }
    func setFavorite(_ memo: Memo, to value: Bool) async throws { fatalError("not used") }
    func setFavorite(_ memos: [Memo], to value: Bool) async throws { fatalError("not used") }
    func updateMemoContent(_ memo: Memo, newTitle: String?, newMemoText: String?) async throws { fatalError("not used") }
}

private extension AuthUser {
    static let sample = AuthUser(id: "test-uid", displayName: "Tester", email: "test@example.com")
}
