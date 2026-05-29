import XCTest
import Domain
@testable import SyncImpl

/// `FirestoreSyncService.syncAction(for:)`이 카테고리 변경 이벤트를 올바른 Firestore 작업으로 환산하는지 검증한다.
final class CategorySyncActionTests: XCTestCase {

    func test_삭제_이벤트는_delete_액션으로_환산된다() {
        let a = UUID()
        let b = UUID()
        XCTAssertEqual(
            FirestoreSyncService.syncAction(for: .delete(categoryIDs: [a, b])),
            .delete(categoryIDs: [a, b])
        )
    }

    func test_생성_이벤트는_upsert_액션으로_환산된다() {
        let id = UUID()
        XCTAssertEqual(
            FirestoreSyncService.syncAction(for: .create(categoryIDs: [id])),
            .upsert(categoryIDs: [id])
        )
    }

    func test_업데이트_이벤트는_연관_attribute의_categoryID로_upsert된다() {
        let id = UUID()
        XCTAssertEqual(
            FirestoreSyncService.syncAction(for: .update(content: .name(categoryIDs: [id]))),
            .upsert(categoryIDs: [id])
        )
        XCTAssertEqual(
            FirestoreSyncService.syncAction(for: .update(content: .modificationDate(categoryIDs: [id]))),
            .upsert(categoryIDs: [id])
        )
    }
}
