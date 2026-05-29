import XCTest
import FirebaseFirestore
import SyncInterface
@testable import SyncImpl

/// Firestore SDK 에러 → `SyncError` 매핑을 검증한다.
/// `SyncError`는 `unknown(Error)` 때문에 Equatable이 아니라, case 패턴 매칭으로 확인한다.
final class FirestoreErrorMapperTests: XCTestCase {

    private func firestoreError(_ code: FirestoreErrorCode.Code) -> NSError {
        NSError(domain: FirestoreErrorDomain, code: code.rawValue)
    }

    func test_unavailable는_network로_매핑된다() {
        guard case .network = FirestoreErrorMapper.syncError(from: firestoreError(.unavailable)) else {
            return XCTFail("network로 매핑되어야 한다")
        }
    }

    func test_permissionDenied는_permissionDenied로_매핑된다() {
        guard case .permissionDenied = FirestoreErrorMapper.syncError(from: firestoreError(.permissionDenied)) else {
            return XCTFail("permissionDenied로 매핑되어야 한다")
        }
    }

    func test_resourceExhausted는_quotaExceeded로_매핑된다() {
        guard case .quotaExceeded = FirestoreErrorMapper.syncError(from: firestoreError(.resourceExhausted)) else {
            return XCTFail("quotaExceeded로 매핑되어야 한다")
        }
    }

    func test_unauthenticated는_unauthenticated로_매핑된다() {
        guard case .unauthenticated = FirestoreErrorMapper.syncError(from: firestoreError(.unauthenticated)) else {
            return XCTFail("unauthenticated로 매핑되어야 한다")
        }
    }

    func test_매핑되지_않은_Firestore_코드는_unknown이다() {
        guard case .unknown = FirestoreErrorMapper.syncError(from: firestoreError(.dataLoss)) else {
            return XCTFail("매핑 규칙에 없는 코드는 unknown이어야 한다")
        }
    }

    func test_Firestore_도메인이_아닌_에러는_unknown이다() {
        let other = NSError(domain: "SomeOtherDomain", code: 42)
        guard case .unknown = FirestoreErrorMapper.syncError(from: other) else {
            return XCTFail("Firestore 도메인이 아니면 unknown이어야 한다")
        }
    }
}
