import XCTest
import Domain
import FirebaseFirestore
@testable import SyncImpl

/// `FirestoreMemoWriter.payload(for:)`의 변환 결과를 검증한다.
///
/// 실제 네트워크 push(`upsert(_:userID:)`)는 Firestore 통합 환경이 필요해 단위 테스트로 다루지 않는다.
final class FirestoreMemoWriterTests: XCTestCase {

    func test_payload는_FirestoreMemo의_모든_필드를_포함한다() throws {
        // given
        let memoID = UUID()
        let creation = Date(timeIntervalSince1970: 1_000_000)
        let modification = Date(timeIntervalSince1970: 1_000_500)
        let memo = makeMemo(
            id: memoID,
            title: "제목",
            text: "본문",
            isFavorite: true,
            isInTrash: false,
            creation: creation,
            modification: modification
        )

        // when
        let payload = try FirestoreMemoWriter.payload(for: memo)

        // then
        XCTAssertEqual(payload["memoID"] as? String, memoID.uuidString)
        XCTAssertEqual(payload["memoTitle"] as? String, "제목")
        XCTAssertEqual(payload["memoText"] as? String, "본문")
        XCTAssertEqual(payload["isFavorite"] as? Bool, true)
        XCTAssertEqual(payload["isInTrash"] as? Bool, false)
        XCTAssertEqual(payload["categoryIDs"] as? [String], [])
    }

    func test_payload의_날짜는_Firestore_Timestamp로_인코딩된다() throws {
        // given
        let creation = Date(timeIntervalSince1970: 1_000_000)
        let modification = Date(timeIntervalSince1970: 1_000_500)
        let memo = makeMemo(creation: creation, modification: modification)

        // when
        let payload = try FirestoreMemoWriter.payload(for: memo)

        // then: Firestore.Encoder는 Swift Date를 Firestore Timestamp로 변환한다
        let creationTimestamp = try XCTUnwrap(payload["creationDate"] as? Timestamp)
        let modificationTimestamp = try XCTUnwrap(payload["modificationDate"] as? Timestamp)
        XCTAssertEqual(creationTimestamp.dateValue(), creation)
        XCTAssertEqual(modificationTimestamp.dateValue(), modification)
    }

    func test_휴지통이_아닌_메모의_deletedDate는_FieldValue_delete로_push된다() throws {
        // given: 휴지통 복원 등으로 deletedDate가 nil인 메모
        let memo = makeMemo(isInTrash: false, deleted: nil)

        // when
        let payload = try FirestoreMemoWriter.payload(for: memo)

        // then: setData(merge: true)가 기존 deletedDate를 보존하지 못하도록 명시적 delete sentinel을 보낸다
        XCTAssertTrue(payload["deletedDate"] is FieldValue)
    }

    func test_휴지통_메모의_deletedDate는_Firestore_Timestamp로_인코딩된다() throws {
        // given
        let deleted = Date(timeIntervalSince1970: 1_000_900)
        let memo = makeMemo(isInTrash: true, deleted: deleted)

        // when
        let payload = try FirestoreMemoWriter.payload(for: memo)

        // then
        let timestamp = try XCTUnwrap(payload["deletedDate"] as? Timestamp)
        XCTAssertEqual(timestamp.dateValue(), deleted)
    }

    func test_payload는_server_timestamp_sentinel을_포함한다() throws {
        // given
        let memo = makeMemo()

        // when
        let payload = try FirestoreMemoWriter.payload(for: memo)

        // then: 실제 시각은 Firestore가 commit 시점에 채우므로 여기서는 sentinel 객체임만 확인
        let sentinel = try XCTUnwrap(payload["serverUpdatedAt"])
        XCTAssertTrue(sentinel is FieldValue)
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
        deleted: Date? = nil
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
            categories: [],
            images: []
        )
    }
}
