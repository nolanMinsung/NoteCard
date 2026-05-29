import XCTest
import Domain
@testable import SyncImpl

/// Domain `Category` ↔ `FirestoreCategory` 변환과 Codable 라운드트립을 검증한다.
final class FirestoreCategoryTests: XCTestCase {

    func test_도메인_카테고리의_모든_필드가_DTO에_복사된다() {
        let id = UUID()
        let creation = Date(timeIntervalSince1970: 1_000_000)
        let modification = Date(timeIntervalSince1970: 1_000_500)
        let category = Domain.Category(id: id, name: "업무", creationDate: creation, modificationDate: modification)

        let dto = FirestoreCategory(category)

        XCTAssertEqual(dto.categoryID, id.uuidString)
        XCTAssertEqual(dto.name, "업무")
        XCTAssertEqual(dto.creationDate, creation)
        XCTAssertEqual(dto.modificationDate, modification)
    }

    func test_toDomain은_모든_필드를_복원한다() throws {
        let id = UUID()
        let creation = Date(timeIntervalSince1970: 1_000_000)
        let modification = Date(timeIntervalSince1970: 1_000_500)
        let dto = FirestoreCategory(
            Domain.Category(id: id, name: "개인", creationDate: creation, modificationDate: modification)
        )

        let category = try XCTUnwrap(dto.toDomain())

        XCTAssertEqual(category.id, id)
        XCTAssertEqual(category.name, "개인")
        XCTAssertEqual(category.creationDate, creation)
        XCTAssertEqual(category.modificationDate, modification)
    }

    func test_categoryID가_UUID가_아니면_toDomain은_nil을_반환한다() {
        let dto = FirestoreCategory(
            categoryID: "not-a-uuid",
            name: "",
            creationDate: .now,
            modificationDate: .now
        )
        XCTAssertNil(dto.toDomain())
    }

    func test_JSON_라운드트립_후에도_모든_필드가_동일하다() throws {
        let original = FirestoreCategory(
            Domain.Category(id: UUID(), name: "왕복", creationDate: .now, modificationDate: .now)
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FirestoreCategory.self, from: encoded)

        XCTAssertEqual(decoded, original)
    }
}
