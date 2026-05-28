import XCTest
import Domain
@testable import SyncImpl

/// `FirestoreSyncService.syncAction(for:)`이 메모 변경 이벤트를 올바른 Firestore 작업으로 환산하는지 검증한다.
final class MemoSyncActionTests: XCTestCase {

    func test_삭제_이벤트는_delete_액션으로_환산된다() {
        let a = UUID()
        let b = UUID()
        XCTAssertEqual(
            FirestoreSyncService.syncAction(for: .delete(memoIDs: [a, b])),
            .delete(memoIDs: [a, b])
        )
    }

    func test_생성_휴지통_복원_이벤트는_upsert_액션으로_환산된다() {
        let id = UUID()
        XCTAssertEqual(FirestoreSyncService.syncAction(for: .create(memoIDs: [id])), .upsert(memoIDs: [id]))
        XCTAssertEqual(FirestoreSyncService.syncAction(for: .trash(memoIDs: [id])), .upsert(memoIDs: [id]))
        XCTAssertEqual(FirestoreSyncService.syncAction(for: .restore(memoIDs: [id])), .upsert(memoIDs: [id]))
    }

    func test_업데이트_이벤트는_연관_attribute의_memoID로_upsert된다() {
        let id = UUID()
        XCTAssertEqual(
            FirestoreSyncService.syncAction(for: .update(content: .titleText(memoIDs: [id]))),
            .upsert(memoIDs: [id])
        )
        XCTAssertEqual(
            FirestoreSyncService.syncAction(for: .update(content: .category(memoIDs: [id]))),
            .upsert(memoIDs: [id])
        )
    }
}
