import XCTest
import Combine
@testable import Shared

/// `@UserDefault` 프로퍼티 래퍼의 동작 검증.
///
/// 래퍼는 `UserDefaults.standard`를 직접 사용하므로, 전역 상태를 건드린 뒤
/// tearDown에서 원래 값으로 복원해 테스트 간 격리를 보장한다.
final class UserDefaultWrapperTests: XCTestCase {

    private let key = UserDefaultsKey.dateFormat
    private var savedValue: Any?

    override func setUp() {
        super.setUp()
        savedValue = UserDefaults.standard.object(forKey: key.rawValue)
        UserDefaults.standard.removeObject(forKey: key.rawValue)
    }

    override func tearDown() {
        UserDefaults.standard.set(savedValue, forKey: key.rawValue)
        super.tearDown()
    }

    func test_저장된_값이_없으면_기본값을_반환한다() {
        // given: 저장된 값이 없는 상태 (setUp에서 키 제거됨)
        let wrapper = UserDefault<String>(key: key, defaultValue: "fallback")

        // when / then
        XCTAssertEqual(wrapper.wrappedValue, "fallback")
    }

    func test_값을_저장하면_그_값을_반환한다() {
        // given
        var wrapper = UserDefault<String>(key: key, defaultValue: "fallback")

        // when
        wrapper.wrappedValue = "stored"

        // then
        XCTAssertEqual(wrapper.wrappedValue, "stored")
    }

    func test_같은_키를_보는_다른_래퍼도_저장된_값을_읽는다() {
        // given: 한 래퍼로 값을 저장하면
        var writer = UserDefault<String>(key: key, defaultValue: "fallback")
        writer.wrappedValue = "shared-value"

        // when: 같은 키를 보는 다른 래퍼는
        let reader = UserDefault<String>(key: key, defaultValue: "fallback")

        // then: 같은 값을 읽는다
        XCTAssertEqual(reader.wrappedValue, "shared-value")
    }
}


/// `OrderSettingManager`의 동작 검증.
///
/// `@MainActor` 싱글톤이므로 테스트 클래스도 `@MainActor`로 둔다.
@MainActor
final class OrderSettingManagerTests: XCTestCase {

    private let criterionKey = "orderCriterion"
    private let ascendingKey = "isOrderAscending"
    private var savedCriterion: Any?
    private var savedAscending: Any?

    override func setUp() {
        super.setUp()
        savedCriterion = UserDefaults.standard.object(forKey: criterionKey)
        savedAscending = UserDefaults.standard.object(forKey: ascendingKey)
    }

    override func tearDown() {
        UserDefaults.standard.set(savedCriterion, forKey: criterionKey)
        UserDefaults.standard.set(savedAscending, forKey: ascendingKey)
        super.tearDown()
    }

    func test_정렬_기준을_설정하면_UserDefaults에_저장된다() {
        // when
        OrderSettingManager.shared.setOrderCriterion(.creationDate)

        // then
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: criterionKey),
            OrderCriterion.creationDate.rawValue
        )
    }

    func test_정렬_기준을_설정하면_변경_이벤트가_방출된다() {
        // given: 변경 이벤트 구독
        var emitCount = 0
        let cancellable = OrderSettingManager.shared.orderSettingChangedPublisher
            .sink { emitCount += 1 }
        defer { cancellable.cancel() }

        // when
        OrderSettingManager.shared.setOrderCriterion(.modificationDate)

        // then
        XCTAssertEqual(emitCount, 1)
    }

    func test_정렬_방향을_설정하면_저장되고_변경_이벤트가_방출된다() {
        // given
        var emitCount = 0
        let cancellable = OrderSettingManager.shared.orderSettingChangedPublisher
            .sink { emitCount += 1 }
        defer { cancellable.cancel() }

        // when
        OrderSettingManager.shared.setIsOrderAscending(true)

        // then
        XCTAssertEqual(UserDefaults.standard.bool(forKey: ascendingKey), true)
        XCTAssertEqual(emitCount, 1)
    }
}


/// `Date` 포맷팅 확장의 동작 검증.
///
/// 시각 표기는 로케일·`isTimeFormat24` 설정에 따라 달라지므로, 검증은
/// 로케일과 무관하게 결정적인 "오늘 / 어제 / 그 외" 분기에 집중한다.
final class DateFormattingTests: XCTestCase {

    func test_오늘_날짜는_오늘_라벨로_시작한다() {
        // given / when
        let result = Date().getCreationDateInString()

        // then
        XCTAssertTrue(result.hasPrefix(L10n.Date.today))
    }

    func test_어제_날짜는_어제_라벨로_시작한다() {
        // given
        let yesterday = Calendar(identifier: .gregorian)
            .date(byAdding: .day, value: -1, to: Date())!

        // when
        let result = yesterday.getCreationDateInString()

        // then
        XCTAssertTrue(result.hasPrefix(L10n.Date.yesterday))
    }

    func test_오래된_날짜는_오늘도_어제도_아닌_일반_형식을_쓴다() {
        // given: 1970년 (오늘도 어제도 아닌 날짜)
        let oldDate = Date(timeIntervalSince1970: 0)

        // when
        let result = oldDate.getCreationDateInString()

        // then: today/yesterday 라벨 대신 일반 날짜 형식이 쓰인다
        XCTAssertFalse(result.hasPrefix(L10n.Date.today))
        XCTAssertFalse(result.hasPrefix(L10n.Date.yesterday))
    }

    func test_수정일_문자열도_오늘이면_오늘_라벨로_시작한다() {
        // given / when
        let result = Date().getModificationDateString()

        // then
        XCTAssertTrue(result.hasPrefix(L10n.Date.today))
    }
}
