import Combine
import XCTest
import SyncInterface
@testable import SyncImpl

/// `FirestoreSyncService`의 status 전이를 검증한다. Firestore 네트워크에는 접근하지 않으며
/// `AuthService` 인증 상태 변경에 따른 lifecycle만 다룬다.
final class FirestoreSyncServiceTests: XCTestCase {

    private var auth: MockAuthService!
    private var sut: FirestoreSyncService!

    override func setUp() {
        super.setUp()
        auth = MockAuthService()
        sut = FirestoreSyncService(authService: auth)
    }

    override func tearDown() {
        sut = nil
        auth = nil
        super.tearDown()
    }

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

        // when: 한 번 더 호출해도 추가 구독이 생기지 않는다 — emit 시 한 번만 전이
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
}

// MARK: - Mock

private final class MockAuthService: AuthService, @unchecked Sendable {

    private let subject = CurrentValueSubject<AuthUser?, Never>(nil)

    var currentUser: AuthUser? { subject.value }

    var authStatePublisher: AnyPublisher<AuthUser?, Never> {
        subject.eraseToAnyPublisher()
    }

    func signInWithApple() async throws -> AuthUser {
        fatalError("not used in tests")
    }

    func signOut() async throws {}

    func deleteAccount() async throws {}

    func emit(_ user: AuthUser?) {
        subject.send(user)
    }
}

private extension AuthUser {
    static let sample = AuthUser(id: "test-uid", displayName: "Tester", email: "test@example.com")
}
