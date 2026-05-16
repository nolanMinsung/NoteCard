import XCTest
import Combine
import Domain
@testable import Data

/// `MemoRepositoryImpl`의 동작(behavior)을 검증하는 통합 테스트.
///
/// 구현 세부사항(predicate, context 상태)이 아니라 Repository의 공개 API를 통해
/// 관찰 가능한 결과만 검증한다. 저장소는 매 테스트마다 `/dev/null` SQLite로 새로
/// 만들어 완전히 격리된 빈 상태에서 시작한다.
final class MemoRepositoryTests: XCTestCase {

    private var stack: CoreDataStack!
    private var sut: MemoRepositoryImpl!
    private var categoryRepository: CategoryRepositoryImpl!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack(inMemory: true)
        sut = MemoRepositoryImpl(stack: stack)
        categoryRepository = CategoryRepositoryImpl(stack: stack)
    }

    override func tearDown() {
        sut = nil
        categoryRepository = nil
        stack = nil
        super.tearDown()
    }

    // MARK: - 생성

    func test_메모를_생성하면_전체_목록에서_조회된다() async throws {
        // when: 메모를 새로 만들면
        let created = try await sut.createNewMemo()

        // then: 전체 메모 목록에서 그 메모가 조회된다
        let all = try await sut.getAllMemos()
        XCTAssertEqual(all.map(\.memoID), [created.memoID])
    }

    func test_새로_생성된_메모는_즐겨찾기도_휴지통도_아니다() async throws {
        // when
        let created = try await sut.createNewMemo()

        // then: 새 메모는 즐겨찾기/휴지통 상태가 아니며 제목·본문이 비어 있다
        XCTAssertFalse(created.isFavorite)
        XCTAssertFalse(created.isInTrash)
        XCTAssertTrue(created.memoTitle.isEmpty)
        XCTAssertTrue(created.memoText.isEmpty)
    }

    // MARK: - 조회

    func test_ID로_조회하면_해당_메모를_반환한다() async throws {
        // given
        let created = try await sut.createNewMemo()

        // when
        let fetched = try await sut.getMemo(id: created.memoID)

        // then
        XCTAssertEqual(fetched.memoID, created.memoID)
    }

    func test_존재하지_않는_ID로_조회하면_에러를_던진다() async throws {
        // when / then: 존재하지 않는 ID로 조회하면 에러를 던진다
        do {
            _ = try await sut.getMemo(id: UUID())
            XCTFail("존재하지 않는 ID로 조회 시 에러를 던져야 한다")
        } catch {
            // 에러 발생 — 통과
        }
    }

    func test_전체_조회시_휴지통_메모는_제외된다() async throws {
        // given: 일반 메모 1개와 휴지통으로 보낸 메모 1개
        let kept = try await sut.createNewMemo()
        let trashed = try await sut.createNewMemo()
        try await sut.moveToTrash(trashed)

        // when
        let all = try await sut.getAllMemos()

        // then: 휴지통 메모는 제외된다
        XCTAssertEqual(all.map(\.memoID), [kept.memoID])
    }

    func test_휴지통_조회시_휴지통에_있는_메모만_반환된다() async throws {
        // given
        _ = try await sut.createNewMemo()
        let trashed = try await sut.createNewMemo()
        try await sut.moveToTrash(trashed)

        // when
        let trash = try await sut.getAllMemosInTrash()

        // then
        XCTAssertEqual(trash.map(\.memoID), [trashed.memoID])
    }

    func test_카테고리_nil로_조회하면_카테고리_없는_메모만_반환된다() async throws {
        // given: 카테고리 없는 메모 1개, 카테고리에 속한 메모 1개
        let uncategorized = try await sut.createNewMemo()
        let categorized = try await sut.createNewMemo()
        let work = try await makeCategory(named: "업무")
        try await sut.addCategories(to: categorized, newCategories: [work])

        // when: category 인자에 nil을 주면
        let results = try await sut.getAllMemos(inCategory: nil)

        // then: 아무 카테고리에도 속하지 않은 메모만 반환된다
        XCTAssertEqual(results.map(\.memoID), [uncategorized.memoID])
    }

    func test_특정_카테고리로_조회하면_그_카테고리의_메모만_반환된다() async throws {
        // given
        let categorized = try await sut.createNewMemo()
        _ = try await sut.createNewMemo()
        let work = try await makeCategory(named: "업무")
        try await sut.addCategories(to: categorized, newCategories: [work])

        // when
        let results = try await sut.getAllMemos(inCategory: work)

        // then
        XCTAssertEqual(results.map(\.memoID), [categorized.memoID])
    }

    // MARK: - 검색

    func test_빈_검색어로_검색하면_결과가_없다() async throws {
        // given
        let memo = try await sut.createNewMemo()
        try await sut.updateMemoContent(memo, newTitle: "제목", newMemoText: "본문")

        // when: 빈 검색어로 검색하면
        let results = try await sut.searchMemo(searchText: "", inCategory: nil)

        // then: 결과가 없다
        XCTAssertTrue(results.isEmpty)
    }

    func test_제목으로_메모를_검색할_수_있다() async throws {
        // given
        let memo = try await sut.createNewMemo()
        try await sut.updateMemoContent(memo, newTitle: "장보기 목록", newMemoText: nil)

        // when
        let results = try await sut.searchMemo(searchText: "장보기", inCategory: nil)

        // then
        XCTAssertEqual(results.map(\.memoID), [memo.memoID])
    }

    func test_본문으로_메모를_검색할_수_있다() async throws {
        // given
        let memo = try await sut.createNewMemo()
        try await sut.updateMemoContent(memo, newTitle: nil, newMemoText: "우유와 계란을 사야 한다")

        // when
        let results = try await sut.searchMemo(searchText: "계란", inCategory: nil)

        // then
        XCTAssertEqual(results.map(\.memoID), [memo.memoID])
    }

    func test_검색은_대소문자를_구분하지_않는다() async throws {
        // given
        let memo = try await sut.createNewMemo()
        try await sut.updateMemoContent(memo, newTitle: "Hello World", newMemoText: nil)

        // when: 소문자로 검색해도
        let results = try await sut.searchMemo(searchText: "hello", inCategory: nil)

        // then: 대소문자 구분 없이 매칭된다
        XCTAssertEqual(results.map(\.memoID), [memo.memoID])
    }

    func test_검색_결과에서_휴지통_메모는_제외된다() async throws {
        // given: 검색어를 포함하지만 휴지통에 있는 메모
        let memo = try await sut.createNewMemo()
        try await sut.updateMemoContent(memo, newTitle: "검색대상", newMemoText: nil)
        try await sut.moveToTrash(memo)

        // when
        let results = try await sut.searchMemo(searchText: "검색대상", inCategory: nil)

        // then: 휴지통 메모는 검색되지 않는다
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - 즐겨찾기

    func test_즐겨찾기로_지정하면_즐겨찾기_목록에_나타난다() async throws {
        // given
        let memo = try await sut.createNewMemo()

        // when
        try await sut.setFavorite(memo, to: true)

        // then
        let favorites = try await sut.getFavoriteMemos()
        XCTAssertEqual(favorites.map(\.memoID), [memo.memoID])
    }

    func test_즐겨찾기를_해제하면_즐겨찾기_목록에서_사라진다() async throws {
        // given: 즐겨찾기로 지정된 메모
        let memo = try await sut.createNewMemo()
        try await sut.setFavorite(memo, to: true)

        // when: 즐겨찾기를 해제하면
        try await sut.setFavorite(memo, to: false)

        // then
        let favorites = try await sut.getFavoriteMemos()
        XCTAssertTrue(favorites.isEmpty)
    }

    func test_즐겨찾기_목록에서_휴지통_메모는_제외된다() async throws {
        // given: 즐겨찾기였다가 휴지통으로 보낸 메모
        let memo = try await sut.createNewMemo()
        try await sut.setFavorite(memo, to: true)
        try await sut.moveToTrash(memo)

        // when
        let favorites = try await sut.getFavoriteMemos()

        // then
        XCTAssertTrue(favorites.isEmpty)
    }

    // MARK: - 삭제 (휴지통)

    func test_휴지통으로_보내면_전체_목록에서_사라진다() async throws {
        // given
        let memo = try await sut.createNewMemo()

        // when
        try await sut.moveToTrash(memo)

        // then
        let all = try await sut.getAllMemos()
        XCTAssertTrue(all.isEmpty)
    }

    func test_휴지통으로_보내면_휴지통_목록에_나타난다() async throws {
        // given
        let memo = try await sut.createNewMemo()

        // when
        try await sut.moveToTrash(memo)

        // then
        let trash = try await sut.getAllMemosInTrash()
        XCTAssertEqual(trash.map(\.memoID), [memo.memoID])
    }

    func test_휴지통으로_보내면_즐겨찾기가_해제된다() async throws {
        // given: 즐겨찾기로 지정된 메모
        let memo = try await sut.createNewMemo()
        try await sut.setFavorite(memo, to: true)

        // when
        try await sut.moveToTrash(memo)

        // then: 휴지통으로 가면 즐겨찾기 상태가 해제된다
        let trashed = try await sut.getAllMemosInTrash().first
        XCTAssertEqual(trashed?.isFavorite, false)
    }

    func test_휴지통으로_보내면_카테고리_연결이_끊긴다() async throws {
        // given: 카테고리에 속한 메모
        let memo = try await sut.createNewMemo()
        let work = try await makeCategory(named: "업무")
        try await sut.addCategories(to: memo, newCategories: [work])

        // when
        try await sut.moveToTrash(memo)

        // then: 휴지통 메모는 더 이상 카테고리에 속하지 않는다
        let trashed = try await sut.getAllMemosInTrash().first
        XCTAssertEqual(trashed?.categories.isEmpty, true)
    }

    // MARK: - 삭제 (영구)

    func test_휴지통의_메모를_영구_삭제하면_완전히_사라진다() async throws {
        // given: 휴지통에 있는 메모
        let memo = try await sut.createNewMemo()
        try await sut.moveToTrash(memo)

        // when
        try await sut.deleteMemo(memo)

        // then: 휴지통에서도 사라진다
        let trash = try await sut.getAllMemosInTrash()
        XCTAssertTrue(trash.isEmpty)
    }

    func test_휴지통에_없는_메모는_영구_삭제해도_그대로_남는다() async throws {
        // given: 휴지통에 없는 일반 메모
        let memo = try await sut.createNewMemo()

        // when: 휴지통에 없는 메모에 hard delete를 시도해도
        try await sut.deleteMemo(memo)

        // then: 메모는 그대로 남아 있다
        let all = try await sut.getAllMemos()
        XCTAssertEqual(all.map(\.memoID), [memo.memoID])
    }

    // MARK: - 복원

    func test_복원하면_휴지통_메모가_전체_목록으로_돌아온다() async throws {
        // given: 휴지통에 있는 메모
        let memo = try await sut.createNewMemo()
        try await sut.moveToTrash(memo)

        // when
        try await sut.restore(memo)

        // then: 전체 목록으로 복원되고 휴지통에서는 사라진다
        let all = try await sut.getAllMemos()
        XCTAssertEqual(all.map(\.memoID), [memo.memoID])
        let trash = try await sut.getAllMemosInTrash()
        XCTAssertTrue(trash.isEmpty)
    }

    // MARK: - 수정

    func test_메모_수정시_제목과_본문이_변경된다() async throws {
        // given
        let memo = try await sut.createNewMemo()

        // when
        try await sut.updateMemoContent(memo, newTitle: "새 제목", newMemoText: "새 본문")

        // then
        let updated = try await sut.getMemo(id: memo.memoID)
        XCTAssertEqual(updated.memoTitle, "새 제목")
        XCTAssertEqual(updated.memoText, "새 본문")
    }

    func test_메모_수정시_nil로_둔_필드는_기존_값이_유지된다() async throws {
        // given: 제목과 본문이 채워진 메모
        let memo = try await sut.createNewMemo()
        try await sut.updateMemoContent(memo, newTitle: "원래 제목", newMemoText: "원래 본문")

        // when: 본문만 갱신하고 제목은 nil로 두면
        try await sut.updateMemoContent(memo, newTitle: nil, newMemoText: "수정된 본문")

        // then: 제목은 유지되고 본문만 바뀐다
        let updated = try await sut.getMemo(id: memo.memoID)
        XCTAssertEqual(updated.memoTitle, "원래 제목")
        XCTAssertEqual(updated.memoText, "수정된 본문")
    }

    func test_카테고리_교체시_기존_것은_사라지고_새것만_남는다() async throws {
        // given: 업무 카테고리에 속한 메모
        let memo = try await sut.createNewMemo()
        let work = try await makeCategory(named: "업무")
        try await sut.addCategories(to: memo, newCategories: [work])

        // when: 카테고리를 개인으로 교체하면
        let personal = try await makeCategory(named: "개인")
        try await sut.replaceCategories(to: memo, newCategories: [personal])

        // then: 기존 카테고리는 사라지고 새 카테고리만 남는다
        let updated = try await sut.getMemo(id: memo.memoID)
        XCTAssertEqual(updated.categories.map(\.name), ["개인"])
    }

    func test_카테고리_제거시_해당_카테고리만_연결_해제된다() async throws {
        // given: 두 카테고리에 속한 메모
        let memo = try await sut.createNewMemo()
        let work = try await makeCategory(named: "업무")
        let personal = try await makeCategory(named: "개인")
        try await sut.addCategories(to: memo, newCategories: [work, personal])

        // when: 한 카테고리를 제거하면
        try await sut.removeCategories(to: memo, newCategories: [work])

        // then: 나머지 카테고리만 남는다
        let updated = try await sut.getMemo(id: memo.memoID)
        XCTAssertEqual(updated.categories.map(\.name), ["개인"])
    }

    // MARK: - 이벤트 퍼블리셔

    func test_메모를_생성하면_퍼블리셔로_생성_이벤트가_방출된다() async throws {
        // given: 업데이트 이벤트 구독
        var received: [MemoRepositoryImpl.MemoUpdateType] = []
        let cancellable = sut.memoUpdatedPublisher.sink { received.append($0) }
        defer { cancellable.cancel() }

        // when
        _ = try await sut.createNewMemo()

        // then
        XCTAssertEqual(received, [.create])
    }

    // MARK: - 배열 일괄 처리

    func test_여러_메모를_한번에_휴지통으로_보낸다() async throws {
        // given
        let memo1 = try await sut.createNewMemo()
        let memo2 = try await sut.createNewMemo()

        // when
        try await sut.moveToTrash([memo1, memo2])

        // then
        let all = try await sut.getAllMemos()
        XCTAssertTrue(all.isEmpty)
        let trash = try await sut.getAllMemosInTrash()
        XCTAssertEqual(Set(trash.map(\.memoID)), [memo1.memoID, memo2.memoID])
    }

    func test_여러_메모를_한번에_복원한다() async throws {
        // given: 휴지통에 있는 메모 2개
        let memo1 = try await sut.createNewMemo()
        let memo2 = try await sut.createNewMemo()
        try await sut.moveToTrash([memo1, memo2])

        // when
        try await sut.restore([memo1, memo2])

        // then
        let all = try await sut.getAllMemos()
        XCTAssertEqual(Set(all.map(\.memoID)), [memo1.memoID, memo2.memoID])
    }

    func test_여러_휴지통_메모를_한번에_영구_삭제한다() async throws {
        // given: 휴지통에 있는 메모 2개
        let memo1 = try await sut.createNewMemo()
        let memo2 = try await sut.createNewMemo()
        try await sut.moveToTrash([memo1, memo2])

        // when
        try await sut.deleteMemos([memo1, memo2])

        // then
        let trash = try await sut.getAllMemosInTrash()
        XCTAssertTrue(trash.isEmpty)
    }

    func test_여러_메모를_한번에_즐겨찾기로_지정한다() async throws {
        // given
        let memo1 = try await sut.createNewMemo()
        let memo2 = try await sut.createNewMemo()

        // when
        try await sut.setFavorite([memo1, memo2], to: true)

        // then
        let favorites = try await sut.getFavoriteMemos()
        XCTAssertEqual(Set(favorites.map(\.memoID)), [memo1.memoID, memo2.memoID])
    }

    func test_여러_메모에_카테고리를_한번에_추가한다() async throws {
        // given
        let memo1 = try await sut.createNewMemo()
        let memo2 = try await sut.createNewMemo()
        let work = try await makeCategory(named: "업무")

        // when
        try await sut.addCategories(to: [memo1, memo2], newCategories: [work])

        // then
        let inWork = try await sut.getAllMemos(inCategory: work)
        XCTAssertEqual(Set(inWork.map(\.memoID)), [memo1.memoID, memo2.memoID])
    }

    func test_여러_메모의_카테고리를_한번에_교체한다() async throws {
        // given: 두 메모가 업무 카테고리에 속함
        let memo1 = try await sut.createNewMemo()
        let memo2 = try await sut.createNewMemo()
        let work = try await makeCategory(named: "업무")
        try await sut.addCategories(to: [memo1, memo2], newCategories: [work])

        // when: 카테고리를 개인으로 교체하면
        let personal = try await makeCategory(named: "개인")
        try await sut.replaceCategories(to: [memo1, memo2], newCategories: [personal])

        // then: 모든 메모가 개인 카테고리로 이동하고 업무에는 남지 않는다
        let inPersonal = try await sut.getAllMemos(inCategory: personal)
        XCTAssertEqual(Set(inPersonal.map(\.memoID)), [memo1.memoID, memo2.memoID])
        let inWork = try await sut.getAllMemos(inCategory: work)
        XCTAssertTrue(inWork.isEmpty)
    }

    func test_여러_메모에서_카테고리를_한번에_제거한다() async throws {
        // given
        let memo1 = try await sut.createNewMemo()
        let memo2 = try await sut.createNewMemo()
        let work = try await makeCategory(named: "업무")
        try await sut.addCategories(to: [memo1, memo2], newCategories: [work])

        // when
        try await sut.removeCategories(to: [memo1, memo2], newCategories: [work])

        // then
        let inWork = try await sut.getAllMemos(inCategory: work)
        XCTAssertTrue(inWork.isEmpty)
    }

    // MARK: - 헬퍼

    /// 카테고리를 생성하고 그에 대응하는 Domain 모델을 돌려준다.
    private func makeCategory(named name: String) async throws -> Domain.Category {
        try await categoryRepository.create(name: name)
        let categories = try await categoryRepository.getAllCategories(
            inOrderOf: .modificationDate,
            isAscending: false
        )
        return try XCTUnwrap(categories.first { $0.name == name })
    }
}
