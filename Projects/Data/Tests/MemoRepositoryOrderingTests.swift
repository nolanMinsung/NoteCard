import XCTest
import Domain
@testable import Data

/// `MemoRepositoryImpl`의 정렬 동작을 검증하는 통합 테스트.
///
/// 정렬 기준(`orderCriterion`)과 방향(`isOrderAscending`)은 `UserDefaults.standard`에서
/// 읽어오므로, 각 테스트는 원하는 값을 직접 설정한다. 전역 상태를 건드리는 만큼
/// setUp에서 기존 값을 저장하고 tearDown에서 복원해 테스트 간 격리를 보장한다.
final class MemoRepositoryOrderingTests: XCTestCase {

    private var stack: CoreDataStack!
    private var sut: MemoRepositoryImpl!

    // MemoRepositoryImpl이 정렬 설정을 읽는 UserDefaults 키
    // (Shared의 UserDefaultsKey.orderCriterion / .isOrderAscending rawValue와 동일)
    private let criterionKey = "orderCriterion"
    private let ascendingKey = "isOrderAscending"
    private var savedCriterion: Any?
    private var savedAscending: Any?

    override func setUp() {
        super.setUp()
        savedCriterion = UserDefaults.standard.object(forKey: criterionKey)
        savedAscending = UserDefaults.standard.object(forKey: ascendingKey)
        stack = CoreDataStack(inMemory: true)
        sut = MemoRepositoryImpl(stack: stack)
    }

    override func tearDown() {
        UserDefaults.standard.set(savedCriterion, forKey: criterionKey)
        UserDefaults.standard.set(savedAscending, forKey: ascendingKey)
        sut = nil
        stack = nil
        super.tearDown()
    }

    /// 정렬 기준은 `NSSortDescriptor`에 그대로 쓰이므로 MemoEntity 속성명("creationDate"
    /// 또는 "modificationDate")이어야 한다.
    private func configureOrdering(criterion: String, ascending: Bool) {
        UserDefaults.standard.set(criterion, forKey: criterionKey)
        UserDefaults.standard.set(ascending, forKey: ascendingKey)
    }

    func test_생성일_오름차순으로_정렬할_수_있다() async throws {
        // given: 생성 순서대로 메모 3개 (creationDate 오름차순)
        let first = try await sut.createNewMemo()
        let second = try await sut.createNewMemo()
        let third = try await sut.createNewMemo()
        configureOrdering(criterion: "creationDate", ascending: true)

        // when
        let all = try await sut.getAllMemos()

        // then
        XCTAssertEqual(all.map(\.memoID), [first.memoID, second.memoID, third.memoID])
    }

    func test_생성일_내림차순으로_정렬할_수_있다() async throws {
        // given
        let first = try await sut.createNewMemo()
        let second = try await sut.createNewMemo()
        let third = try await sut.createNewMemo()
        configureOrdering(criterion: "creationDate", ascending: false)

        // when
        let all = try await sut.getAllMemos()

        // then: 최신 생성 메모가 맨 앞
        XCTAssertEqual(all.map(\.memoID), [third.memoID, second.memoID, first.memoID])
    }

    func test_수정일_기준_정렬은_생성일_정렬과_독립적으로_동작한다() async throws {
        // given: 생성 순서는 first < second < third
        let first = try await sut.createNewMemo()
        let second = try await sut.createNewMemo()
        let third = try await sut.createNewMemo()
        // first를 가장 마지막에 수정 → modificationDate는 first가 가장 최신이 된다
        try await sut.updateMemoContent(first, newTitle: "수정됨", newMemoText: nil)
        configureOrdering(criterion: "modificationDate", ascending: false)

        // when
        let all = try await sut.getAllMemos()

        // then: modificationDate 내림차순 → first가 맨 앞 (creationDate 정렬이라면 맨 뒤였을 것)
        XCTAssertEqual(all.map(\.memoID), [first.memoID, third.memoID, second.memoID])
    }

    func test_즐겨찾기_목록도_설정된_정렬_순서를_따른다() async throws {
        // given
        let first = try await sut.createNewMemo()
        let second = try await sut.createNewMemo()
        try await sut.setFavorite(first, to: true)
        try await sut.setFavorite(second, to: true)
        configureOrdering(criterion: "creationDate", ascending: true)

        // when
        let favorites = try await sut.getFavoriteMemos()

        // then
        XCTAssertEqual(favorites.map(\.memoID), [first.memoID, second.memoID])
    }
}
