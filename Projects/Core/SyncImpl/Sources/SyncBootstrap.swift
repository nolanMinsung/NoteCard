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

    /// 메모용 동일 패턴. `categoryResolver`·`imageResolver`는 보통 각각 `makeCategoryRepository` /
    /// `makeImageRepository`의 결과(라우터)를 그대로 전달해 인증 상태에 맞춰 함께 전환되게 한다.
    public static func makeMemoRepository(
        authService: AuthService,
        anonymousImpl: MemoRepository,
        categoryResolver: CategoryRepository,
        imageResolver: ImageRepository
    ) -> MemoRepository {
        guard FirebaseApp.app() != nil else {
            return anonymousImpl
        }
        return MemoRepositoryRouter(
            authService: authService,
            anonymousImpl: anonymousImpl,
            categoryResolver: categoryResolver,
            imageResolver: imageResolver
        )
    }

    /// 이미지용 동일 패턴. `anonymousMemoRepository`는 로그인 시 익명 이미지 enumeration을 위해 필요
    /// (이미지가 메모 sub-collection으로 묶이는 구조라 메모 목록부터 알아야 함).
    public static func makeImageRepository(
        authService: AuthService,
        anonymousImpl: ImageRepository,
        anonymousMemoRepository: MemoRepository
    ) -> ImageRepository {
        guard FirebaseApp.app() != nil else {
            return anonymousImpl
        }
        return ImageRepositoryRouter(
            authService: authService,
            anonymousImpl: anonymousImpl,
            anonymousMemoRepository: anonymousMemoRepository
        )
    }

    /// FirebaseApp 설정이 완료돼 있으면 데이터 정리 + Auth user 삭제를 함께 수행하는 서비스를,
    /// 아니면 호출 시 missingFirebase 를 던지는 No-op 을 반환.
    public static func makeAccountDeletionService(
        authService: AuthService,
        accountSentinelService: AccountSentinelService,
        memoRepository: MemoRepository,
        categoryRepository: CategoryRepository,
        imageRepository: ImageRepository
    ) -> AccountDeletionService {
        guard FirebaseApp.app() != nil else {
            return NoOpAccountDeletionService()
        }
        return FirebaseAccountDeletionService(
            authService: authService,
            accountSentinelService: accountSentinelService,
            memoRepository: memoRepository,
            categoryRepository: categoryRepository,
            imageRepository: imageRepository
        )
    }

    /// 계정의 sentinel doc 을 관리하는 서비스. 사인인 시 자동 생성·감시, cross-device 계정 삭제를
    /// .removed 이벤트로 즉시 감지해 강제 signOut.
    public static func makeAccountSentinelService(
        authService: AuthService
    ) -> AccountSentinelService {
        guard FirebaseApp.app() != nil else {
            return NoOpAccountSentinelService()
        }
        return FirebaseAccountSentinelService(authService: authService)
    }
}
