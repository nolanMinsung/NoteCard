import XCTest
import Domain
@testable import SyncImpl

/// Domain `Memo` → `FirestoreMemo` 변환과 Codable 라운드트립을 검증한다.
final class FirestoreMemoTests: XCTestCase {

    // MARK: - Domain → DTO

    func test_도메인_메모의_모든_필드가_DTO에_복사된다() {
        // given
        let memoID = UUID()
        let creation = Date(timeIntervalSince1970: 1_000_000)
        let modification = Date(timeIntervalSince1970: 1_000_500)
        let deleted = Date(timeIntervalSince1970: 1_000_900)
        let memo = makeMemo(
            id: memoID,
            title: "제목",
            text: "본문",
            isFavorite: true,
            isInTrash: true,
            creation: creation,
            modification: modification,
            deleted: deleted,
            categories: []
        )

        // when
        let dto = FirestoreMemo(memo)

        // then
        XCTAssertEqual(dto.memoID, memoID.uuidString)
        XCTAssertEqual(dto.memoTitle, "제목")
        XCTAssertEqual(dto.memoText, "본문")
        XCTAssertTrue(dto.isFavorite)
        XCTAssertTrue(dto.isInTrash)
        XCTAssertEqual(dto.creationDate, creation)
        XCTAssertEqual(dto.modificationDate, modification)
        XCTAssertEqual(dto.deletedDate, deleted)
        XCTAssertEqual(dto.categoryIDs, [])
    }

    func test_삭제되지_않은_메모의_deletedDate는_nil로_매핑된다() {
        // given
        let memo = makeMemo(isInTrash: false, deleted: nil)

        // when
        let dto = FirestoreMemo(memo)

        // then
        XCTAssertNil(dto.deletedDate)
    }

    func test_categoryIDs는_uuidString_사전순으로_정렬된다() {
        // given: 의도적으로 사전순 역순으로 배치된 카테고리들
        let earlyID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let midID   = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let lateID  = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        let categories: Set<Domain.Category> = [
            Domain.Category(id: lateID,  name: "C", creationDate: .now, modificationDate: .now),
            Domain.Category(id: earlyID, name: "A", creationDate: .now, modificationDate: .now),
            Domain.Category(id: midID,   name: "B", creationDate: .now, modificationDate: .now),
        ]
        let memo = makeMemo(categories: categories)

        // when
        let dto = FirestoreMemo(memo)

        // then
        XCTAssertEqual(dto.categoryIDs, [earlyID.uuidString, midID.uuidString, lateID.uuidString])
    }

    // MARK: - Codable 라운드트립

    func test_JSON_라운드트립_후에도_모든_필드가_동일하다() throws {
        // given
        let memo = makeMemo(
            title: "round",
            text: "trip",
            isFavorite: true,
            isInTrash: false,
            categories: [
                Domain.Category(id: UUID(), name: "A", creationDate: .now, modificationDate: .now),
                Domain.Category(id: UUID(), name: "B", creationDate: .now, modificationDate: .now),
            ]
        )
        let original = FirestoreMemo(memo)

        // when
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FirestoreMemo.self, from: encoded)

        // then
        XCTAssertEqual(decoded, original)
    }

    // MARK: - DTO → Domain (역변환)

    func test_toDomain은_주입된_카테고리와_함께_모든_필드를_복원한다() throws {
        // given
        let memoID = UUID()
        let creation = Date(timeIntervalSince1970: 1_000_000)
        let modification = Date(timeIntervalSince1970: 1_000_500)
        let deleted = Date(timeIntervalSince1970: 1_000_900)
        let dto = FirestoreMemo(makeMemo(
            id: memoID, title: "제목", text: "본문",
            isFavorite: true, isInTrash: true,
            creation: creation, modification: modification, deleted: deleted
        ))
        let categories: Set<Domain.Category> = [
            Domain.Category(id: UUID(), name: "업무", creationDate: .now, modificationDate: .now)
        ]

        // when
        let memo = try XCTUnwrap(dto.toDomain(categories: categories))

        // then
        XCTAssertEqual(memo.memoID, memoID)
        XCTAssertEqual(memo.memoTitle, "제목")
        XCTAssertEqual(memo.memoText, "본문")
        XCTAssertTrue(memo.isFavorite)
        XCTAssertTrue(memo.isInTrash)
        XCTAssertEqual(memo.creationDate, creation)
        XCTAssertEqual(memo.modificationDate, modification)
        XCTAssertEqual(memo.deletedDate, deleted)
        XCTAssertEqual(memo.categories, categories)
        XCTAssertTrue(memo.images.isEmpty, "이미지는 별도 동기화이므로 비어 있어야 한다")
    }

    func test_memoID가_UUID가_아니면_toDomain은_nil을_반환한다() {
        let dto = FirestoreMemo(
            memoID: "not-a-uuid",
            memoTitle: "", memoText: "",
            isFavorite: false, isInTrash: false,
            creationDate: .now, modificationDate: .now, deletedDate: nil,
            categoryIDs: []
        )
        XCTAssertNil(dto.toDomain(categories: []))
    }

    func test_categoryUUIDs는_파싱가능한_ID만_UUID로_돌려준다() {
        let valid = UUID()
        let dto = FirestoreMemo(
            memoID: UUID().uuidString,
            memoTitle: "", memoText: "",
            isFavorite: false, isInTrash: false,
            creationDate: .now, modificationDate: .now, deletedDate: nil,
            categoryIDs: [valid.uuidString, "broken"]
        )
        XCTAssertEqual(dto.categoryUUIDs, [valid])
    }

    func test_Memo_to_DTO_to_Memo_라운드트립이_원본과_같다() throws {
        // given: 카테고리를 가진 메모
        let categories: Set<Domain.Category> = [
            Domain.Category(id: UUID(), name: "A", creationDate: .now, modificationDate: .now),
            Domain.Category(id: UUID(), name: "B", creationDate: .now, modificationDate: .now),
        ]
        let original = makeMemo(title: "왕복", text: "검증", isFavorite: true, categories: categories)

        // when: Memo → DTO → 같은 카테고리 주입해 복원
        let restored = try XCTUnwrap(FirestoreMemo(original).toDomain(categories: categories))

        // then: 이미지를 제외한 모든 필드가 원본과 동일
        XCTAssertEqual(restored, original)
    }

    // MARK: - 헬퍼

    private func makeMemo(
        id: UUID = UUID(),
        title: String = "",
        text: String = "",
        isFavorite: Bool = false,
        isInTrash: Bool = false,
        creation: Date = Date(timeIntervalSince1970: 0),
        modification: Date = Date(timeIntervalSince1970: 0),
        deleted: Date? = nil,
        categories: Set<Domain.Category> = []
    ) -> Memo {
        Memo(
            memoID: id,
            creationDate: creation,
            modificationDate: modification,
            deletedDate: deleted,
            isFavorite: isFavorite,
            isInTrash: isInTrash,
            memoText: text,
            memoTitle: title,
            categories: categories,
            images: []
        )
    }
}
