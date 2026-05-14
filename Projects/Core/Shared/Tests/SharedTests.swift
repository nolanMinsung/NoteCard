import XCTest
@testable import Shared

final class StringLocalizedTests: XCTestCase {

    /// Localization key가 xcstrings에 없으면 NSLocalizedString이 fallback으로 key를 그대로 반환한다.
    /// 이 동작은 SharedResources.bundle을 통과해서도 일관되어야 한다.
    func test_localized_returnsKeyForMissingEntry() {
        let missingKey = "test.totally.missing.key.\(UUID().uuidString)"
        XCTAssertEqual(missingKey.localized(value: missingKey), missingKey)
    }
}
