import XCTest
import Domain
import FirebaseFirestore
@testable import SyncImpl

/// `FirestoreCategoryWriter.payload(for:)`의 변환 결과를 검증한다.
/// 실제 네트워크 push는 Firestore 통합 환경이 필요해 단위 테스트로 다루지 않는다.
final class FirestoreCategoryWriterTests: XCTestCase {

    func test_payload는_카테고리의_모든_필드를_포함한다() throws {
        let id = UUID()
        let creation = Date(timeIntervalSince1970: 1_000_000)
        let modification = Date(timeIntervalSince1970: 1_000_500)
        let category = Domain.Category(id: id, name: "업무", creationDate: creation, modificationDate: modification)

        let payload = try FirestoreCategoryWriter.payload(for: category)

        XCTAssertEqual(payload["categoryID"] as? String, id.uuidString)
        XCTAssertEqual(payload["name"] as? String, "업무")
    }

    func test_payload의_날짜는_Firestore_Timestamp로_인코딩된다() throws {
        let creation = Date(timeIntervalSince1970: 1_000_000)
        let modification = Date(timeIntervalSince1970: 1_000_500)
        let category = Domain.Category(id: UUID(), name: "", creationDate: creation, modificationDate: modification)

        let payload = try FirestoreCategoryWriter.payload(for: category)

        let creationTimestamp = try XCTUnwrap(payload["creationDate"] as? Timestamp)
        let modificationTimestamp = try XCTUnwrap(payload["modificationDate"] as? Timestamp)
        XCTAssertEqual(creationTimestamp.dateValue(), creation)
        XCTAssertEqual(modificationTimestamp.dateValue(), modification)
    }

    func test_payload는_server_timestamp_sentinel을_포함한다() throws {
        let category = Domain.Category(id: UUID(), name: "", creationDate: .now, modificationDate: .now)

        let payload = try FirestoreCategoryWriter.payload(for: category)

        let sentinel = try XCTUnwrap(payload["serverUpdatedAt"])
        XCTAssertTrue(sentinel is FieldValue)
    }
}
