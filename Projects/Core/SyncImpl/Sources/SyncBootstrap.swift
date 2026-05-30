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
        memoRepository: MemoRepository,
        categoryRepository: CategoryRepository
    ) -> SyncService {
        guard FirebaseApp.app() != nil else {
            return NoOpSyncService()
        }
        return FirestoreSyncService(
            authService: authService,
            memoRepository: memoRepository,
            memoWriter: FirestoreMemoWriter(),
            categoryRepository: categoryRepository,
            categoryWriter: FirestoreCategoryWriter()
        )
    }

    /// 명시적으로 No-op 구현을 만들고 싶을 때 (테스트·프리뷰 등).
    public static func makeNoOpSyncService() -> SyncService {
        NoOpSyncService()
    }

    /// FirebaseApp 설정이 완료돼 있으면 인증 상태에 따라 Core Data ↔ Firestore를 스위칭하는 라우터를,
    /// 아니면 익명 impl을 그대로 반환. (Firebase 미설정 환경에서 `.firestore()` fatalError 회피)
    public static func makeCategoryRepository(
        authService: AuthService,
        anonymousImpl: CategoryRepository
    ) -> CategoryRepository {
        guard FirebaseApp.app() != nil else {
            return anonymousImpl
        }
        return CategoryRepositoryRouter(authService: authService, anonymousImpl: anonymousImpl)
    }
}
