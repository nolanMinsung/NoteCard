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
