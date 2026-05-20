import XCTest
import Combine
@testable import Domain

/// `AnonymousUserIDProvider`가 익명(미로그인) 상태의 default 동작을 충족하는지 검증.
final class CurrentUserIDProviderTests: XCTestCase {

    func test_anonymous_provider의_currentUserID는_nil이다() {
        let provider = AnonymousUserIDProvider()
        XCTAssertNil(provider.currentUserID)
    }

    func test_anonymous_provider의_publisher는_구독_즉시_nil을_emit한다() {
        // given
        let provider = AnonymousUserIDProvider()

        // when
        var didReceive = false
        var receivedValue: String?
        let cancellable = provider.currentUserIDPublisher.sink { value in
            didReceive = true
            receivedValue = value
        }
        defer { cancellable.cancel() }

        // then
        XCTAssertTrue(didReceive, "CurrentValueSubject 기반이므로 구독 즉시 값을 받아야 한다.")
        XCTAssertNil(receivedValue)
    }
}
