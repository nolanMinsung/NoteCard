import XCTest
import Domain
@testable import Data

/// `CategoryRepositoryImpl`의 동작(behavior)을 검증하는 통합 테스트.
///
/// 공개 API를 통해 관찰 가능한 결과만 검증하며, 저장소는 매 테스트마다
/// `/dev/null` SQLite로 새로 만들어 격리한다.
final class CategoryRepositoryTests: XCTestCase {

    private var stack: CoreDataStack!
    private var sut: CategoryRepositoryImpl!
    private var memoRepository: MemoRepositoryImpl!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack(inMemory: true)
        sut = CategoryRepositoryImpl(stack: stack)
        memoRepository = MemoRepositoryImpl(stack: stack)
    }

    override func tearDown() {
        sut = nil
        memoRepository = nil
        stack = nil
        super.tearDown()
    }

    // MARK: - 생성

    func test_카테고리를_생성하면_전체_목록에서_조회된다() async throws {
        // when
        try await sut.create(name: "업무")

        // then
        let names = try await allCategoryNames()
        XCTAssertEqual(names, ["업무"])
    }

    func test_중복된_이름으로_카테고리를_생성하면_에러를_던진다() async throws {
        // given: 이미 존재하는 카테고리
        try await sut.create(name: "업무")

        // when / then: 같은 이름으로 다시 만들면 에러를 던진다
        do {
            try await sut.create(name: "업무")
            XCTFail("중복된 이름의 카테고리 생성 시 에러를 던져야 한다")
        } catch {
            // 에러 발생 — 통과
        }
    }

    func test_중복된_이름으로_생성을_시도해도_카테고리가_늘어나지_않는다() async throws {
        // given
        try await sut.create(name: "업무")

        // when: 중복 생성을 시도하면 (에러 발생)
        _ = try? await sut.create(name: "업무")

        // then: 카테고리는 여전히 1개뿐이다
        let names = try await allCategoryNames()
        XCTAssertEqual(names, ["업무"])
    }

    // MARK: - 조회

    func test_생성한_모든_카테고리가_조회된다() async throws {
        // given
        try await sut.create(name: "업무")
        try await sut.create(name: "개인")
        try await sut.create(name: "공부")

        // when
        let names = try await allCategoryNames()

        // then
        XCTAssertEqual(Set(names), ["업무", "개인", "공부"])
    }

    func test_메모별_조회시_그_메모에_연결된_카테고리만_반환된다() async throws {
        // given: 메모에 업무 카테고리만 연결
        try await sut.create(name: "업무")
        try await sut.create(name: "개인")
        let work = try await category(named: "업무")
        let memo = try await memoRepository.createNewMemo()
        try await memoRepository.addCategories(to: memo, newCategories: [work])

        // when
        let linked = try await sut.getAllCategories(
            ofMemo: memo,
            inOrderOf: .modificationDate,
            isAscending: false
        )

        // then
        XCTAssertEqual(linked.map(\.name), ["업무"])
    }

    // MARK: - 검색

    func test_검색은_대소문자를_구분하지_않는_부분_문자열로_매칭한다() async throws {
        // given
        try await sut.create(name: "Work")
        try await sut.create(name: "Personal")

        // when: 소문자 부분 문자열로 검색하면
        let results = try await sut.searchCategory("work", inOrderOf: .name, isAscending: true)

        // then: 대소문자 구분 없이 매칭된다
        XCTAssertEqual(results.map(\.name), ["Work"])
    }

    func test_일치하는_카테고리가_없으면_검색_결과가_비어있다() async throws {
        // given
        try await sut.create(name: "업무")

        // when
        let results = try await sut.searchCategory("존재하지않음", inOrderOf: .name, isAscending: true)

        // then
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - 수정

    func test_카테고리_이름을_변경할_수_있다() async throws {
        // given
        try await sut.create(name: "업무")
        let work = try await category(named: "업무")

        // when
        try await sut.changeCategoryName(work, newName: "회사")

        // then
        let names = try await allCategoryNames()
        XCTAssertEqual(names, ["회사"])
    }

    func test_이미_존재하는_이름으로_변경하면_에러를_던진다() async throws {
        // given: 두 개의 카테고리
        try await sut.create(name: "업무")
        try await sut.create(name: "개인")
        let personal = try await category(named: "개인")

        // when / then: 이미 존재하는 이름으로 바꾸려 하면 에러를 던진다
        do {
            try await sut.changeCategoryName(personal, newName: "업무")
            XCTFail("이미 존재하는 이름으로 변경 시 에러를 던져야 한다")
        } catch {
            // 에러 발생 — 통과
        }
    }

    // MARK: - 삭제

    func test_카테고리를_삭제하면_전체_목록에서_사라진다() async throws {
        // given
        try await sut.create(name: "업무")
        let work = try await category(named: "업무")

        // when
        try await sut.deleteCategory(work)

        // then
        let names = try await allCategoryNames()
        XCTAssertTrue(names.isEmpty)
    }

    // MARK: - 메모 개수

    func test_memoCount는_카테고리에_속한_메모_수를_반환한다() async throws {
        // given: 한 카테고리에 메모 2개를 연결
        try await sut.create(name: "업무")
        let work = try await category(named: "업무")
        let memo1 = try await memoRepository.createNewMemo()
        let memo2 = try await memoRepository.createNewMemo()
        try await memoRepository.addCategories(to: memo1, newCategories: [work])
        try await memoRepository.addCategories(to: memo2, newCategories: [work])

        // when
        let count = try await sut.memoCount(of: work)

        // then
        XCTAssertEqual(count, 2)
    }

    func test_메모가_없는_카테고리의_memoCount는_0이다() async throws {
        // given
        try await sut.create(name: "업무")
        let work = try await category(named: "업무")

        // when
        let count = try await sut.memoCount(of: work)

        // then
        XCTAssertEqual(count, 0)
    }

    // MARK: - 헬퍼

    private func allCategoryNames() async throws -> [String] {
        try await sut.getAllCategories(inOrderOf: .modificationDate, isAscending: false)
            .map(\.name)
    }

    private func category(named name: String) async throws -> Domain.Category {
        let categories = try await sut.getAllCategories(
            inOrderOf: .modificationDate,
            isAscending: false
        )
        return try XCTUnwrap(categories.first { $0.name == name })
    }
}
