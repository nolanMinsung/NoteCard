//
//  AppEnvironment.swift
//  NoteCard
//

import Foundation
import Data
import Domain
import AnalyticsInterface
import AnalyticsImpl
import SyncInterface
import SyncImpl

/// 앱 전체에서 공유되는 의존성 묶음.
///
/// 프로세스 수명 동안 단 하나만 생성되어 `AppDelegate`가 소유하고,
/// `SceneDelegate`를 거쳐 화면 계층으로 생성자 주입된다.
/// Repository 구현체는 모두 같은 `CoreDataStack` 인스턴스를 공유하므로,
/// Combine publisher 이벤트도 화면 간에 끊김 없이 전달된다.
struct AppEnvironment {

    let memoRepository: MemoRepository
    let categoryRepository: CategoryRepository
    let imageRepository: ImageRepository
    let analytics: Analytics
    let authService: AuthService
    let syncService: SyncService

    private let dataLayer: UserScopedDataLayer

    /// 현재 사용자에 해당하는 Core Data stack. 사용자 변경 시점에 dataLayer가 새 stack으로 교체한다.
    var coreDataStack: CoreDataStack { dataLayer.currentStack }

    init() {
        // FirebaseApp.configure()는 setUpAnalytics 안에서 (plist가 있을 때만) 호출됨.
        // SyncBootstrap이 FirebaseApp.app() 존재 여부를 보고 Firebase/No-op 구현을 고른다.
        self.analytics = Self.setUpAnalytics()
        let authService = SyncBootstrap.makeAuthService()
        self.authService = authService

        // AuthService의 인증 상태를 CurrentUserIDProvider 형태로 어댑팅.
        // 로그인/로그아웃에 따라 UserScopedDataLayer가 사용자별 stack으로 자동 교체한다.
        let userIDProvider = AuthServiceUserIDProvider(authService: authService)

        // 데이터 레이어가 익명 store를 열기 전에 레거시 데이터를 이전한다 (1회, 멱등).
        // 실패 시 Debug 빌드에선 즉시 trap, Release 빌드에선 no-op이 되어 다음 실행에 재시도된다.
        // TODO: Crashlytics non-fatal로 prod 가시성 확보 — onError 클로저는 그 의존성 주입을 위한 자리.
        LegacyStoreMigrator.migrateIfNeeded(
            anonymousStoreURL: UserScopedDataLayer.anonymousStoreURL(),
            onError: { error in assertionFailure("LegacyStoreMigrator 실패: \(error)") }
        )

        let dataLayer = UserScopedDataLayer(
            userIDProvider: userIDProvider,
            onMigrationError: { error in assertionFailure("AnonymousToUserMigrator 실패: \(error)") }
        )
        self.dataLayer = dataLayer

        // v3 모델로 마이그레이션된 store에서 categoryID가 nil인 row를 채움 (1회, 멱등).
        // Core Data lightweight migration이 row별 다른 UUID를 부여 못 해 코드로 backfill.
        CategoryUUIDBackfiller.backfill(
            in: dataLayer.currentStack,
            onError: { error in assertionFailure("CategoryUUIDBackfiller 실패: \(error)") }
        )

        let memoRepository = MemoRepositoryImpl(dataLayer: dataLayer)
        self.memoRepository = memoRepository
        // SPIKE: 옵션 B 검증 — 카테고리는 Router로 감싸 인증 상태에 따라 Core Data ↔ Firestore 전환.
        // UI는 Router를 보고, SyncService에는 underlying Core Data impl을 넘겨 이중쓰기를 피한다.
        let categoryRepositoryCoreData = CategoryRepositoryImpl(dataLayer: dataLayer)
        self.categoryRepository = CategoryRepositoryRouter(
            authService: authService,
            anonymousImpl: categoryRepositoryCoreData
        )
        self.imageRepository = ImageRepositoryImpl(dataLayer: dataLayer, memoRepository: memoRepository)

        // FirebaseApp 설정이 있으면 Firestore 기반 동기화, 아니면 No-op fallback.
        // 인스턴스만 보관하고 실제 lifecycle 시작(start())은 AppDelegate에서 명시 호출.
        self.syncService = SyncBootstrap.makeSyncService(
            authService: authService,
            memoRepository: memoRepository,
            categoryRepository: categoryRepositoryCoreData
        )
    }

    /// Crashlytics를 켜고(가능하면) Amplitude 기반 `Analytics`를 만든다.
    ///
    /// Firebase 설정 파일(`GoogleService-Info.plist`)이나 Amplitude API Key가
    /// 빌드에 포함돼 있지 않으면 해당 기능만 조용히 비활성된다 — 키 없이도
    /// 앱은 정상 동작한다.
    private static func setUpAnalytics() -> Analytics {
        if Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil {
            AnalyticsBootstrap.startCrashReporting()
        }

        let apiKey = Bundle.main.object(forInfoDictionaryKey: "AmplitudeAPIKey") as? String ?? ""
        guard !apiKey.isEmpty else {
            return AnalyticsBootstrap.makeNoOpAnalytics()
        }
        return AnalyticsBootstrap.makeAnalytics(amplitudeAPIKey: apiKey)
    }
}
