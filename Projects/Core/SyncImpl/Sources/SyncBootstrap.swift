//
//  SyncBootstrap.swift
//  NoteCard
//

import Domain
import Foundation
import FirebaseCore
import SyncInterface

/// 동기화 SDK 조립 지점. App composition root에서 호출한다.
///
/// `FirebaseApp.configure()`는 분석 부트스트랩(`AnalyticsBootstrap.startCrashReporting`)에서
/// 먼저 수행되어 있어야 한다. 설정이 없으면 No-op 구현이 반환되어 앱은 정상 동작하되
/// 동기화만 비활성된다.
public enum SyncBootstrap {

    /// FirebaseApp 설정이 완료돼 있으면 Firebase 기반 `AuthService`를, 아니면 No-op 구현을 반환.
    public static func makeAuthService() -> AuthService {
        guard FirebaseApp.app() != nil else {
            return NoOpAuthService()
        }
        return FirebaseAuthService()
    }

    /// 명시적으로 No-op 구현을 만들고 싶을 때 (테스트·프리뷰 등).
    public static func makeNoOpAuthService() -> AuthService {
        NoOpAuthService()
    }

    /// FirebaseApp 설정이 완료돼 있으면 Firestore 기반 `SyncService`를, 아니면 No-op 구현을 반환.
    public static func makeSyncService(
        authService: AuthService,
        memoRepository: MemoRepository
    ) -> SyncService {
        guard FirebaseApp.app() != nil else {
            return NoOpSyncService()
        }
        return FirestoreSyncService(
            authService: authService,
            memoRepository: memoRepository,
            memoWriter: FirestoreMemoWriter()
        )
    }

    /// 명시적으로 No-op 구현을 만들고 싶을 때 (테스트·프리뷰 등).
    public static func makeNoOpSyncService() -> SyncService {
        NoOpSyncService()
    }
}
