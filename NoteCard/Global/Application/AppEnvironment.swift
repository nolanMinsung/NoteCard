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
    let accountSentinelService: AccountSentinelService
    let accountDeletionService: AccountDeletionService
    let syncStatusService: SyncStatusService
    let migrationCleanupCoordinator: AnonymousMigrationCleanupCoordinator
    let firstSignInReadinessCoordinator: FirstSignInReadinessCoordinator
    let signOutCoordinator: SignOutCoordinator
    let pendingUploadResumeTrigger: PendingUploadResumeTrigger

    let coreDataStack: CoreDataStack

    init() {
        // FirebaseApp.configure()는 setUpAnalytics 안에서 (plist가 있을 때만) 호출됨.
        // SyncBootstrap이 FirebaseApp.app() 존재 여부를 보고 Firebase/No-op 구현을 고른다.
        self.analytics = Self.setUpAnalytics()
        let authService = SyncBootstrap.makeAuthService()
        self.authService = authService

        let anonymousStoreURL = Self.makeAnonymousStoreURL()
        LegacyStoreMigrator.migrateIfNeeded(
            anonymousStoreURL: anonymousStoreURL,
            onError: { error in assertionFailure("LegacyStoreMigrator 실패: \(error)") }
        )

        let coreDataStack = CoreDataStack(storeURL: anonymousStoreURL)
        self.coreDataStack = coreDataStack

        // v3 모델로 마이그레이션된 store에서 categoryID가 nil인 row를 채움 (1회, 멱등).
        // Core Data lightweight migration이 row별 다른 UUID를 부여 못 해 코드로 backfill.
        CategoryUUIDBackfiller.backfill(
            in: coreDataStack,
            onError: { error in assertionFailure("CategoryUUIDBackfiller 실패: \(error)") }
        )

        let memoRepositoryCoreData = MemoRepositoryImpl(stack: coreDataStack)
        let categoryRepositoryCoreData = CategoryRepositoryImpl(stack: coreDataStack)
        let imageRepositoryCoreData = ImageRepositoryImpl(stack: coreDataStack, memoRepository: memoRepositoryCoreData)
        let migrationCleanupCoordinator = AnonymousMigrationCleanupCoordinator(coreDataStack: coreDataStack)
        self.migrationCleanupCoordinator = migrationCleanupCoordinator
        let categoryRepository = SyncBootstrap.makeCategoryRepository(
            authService: authService,
            anonymousImpl: categoryRepositoryCoreData,
            cleanupCoordinator: migrationCleanupCoordinator
        )
        self.categoryRepository = categoryRepository
        let imageRepository = SyncBootstrap.makeImageRepository(
            authService: authService,
            anonymousImpl: imageRepositoryCoreData,
            anonymousMemoRepository: memoRepositoryCoreData,
            cleanupCoordinator: migrationCleanupCoordinator
        )
        self.imageRepository = imageRepository
        let memoRepository = SyncBootstrap.makeMemoRepository(
            authService: authService,
            anonymousImpl: memoRepositoryCoreData,
            categoryResolver: categoryRepository,
            imageResolver: imageRepository,
            cleanupCoordinator: migrationCleanupCoordinator
        )
        self.memoRepository = memoRepository
        let accountSentinelService = SyncBootstrap.makeAccountSentinelService(authService: authService)
        self.accountSentinelService = accountSentinelService
        self.accountDeletionService = SyncBootstrap.makeAccountDeletionService(
            authService: authService,
            accountSentinelService: accountSentinelService,
            memoRepository: memoRepository,
            categoryRepository: categoryRepository,
            imageRepository: imageRepository
        )
        self.syncStatusService = SyncBootstrap.makeSyncStatusService(
            authService: authService,
            memoRepository: memoRepository,
            categoryRepository: categoryRepository
        )
        self.firstSignInReadinessCoordinator = SyncBootstrap.makeFirstSignInReadinessCoordinator(
            cleanupCoordinator: migrationCleanupCoordinator,
            memoRepository: memoRepository,
            categoryRepository: categoryRepository,
            imageRepository: imageRepository
        )
        self.signOutCoordinator = SyncBootstrap.makeSignOutCoordinator(authService: authService)
        self.pendingUploadResumeTrigger = SyncBootstrap.makePendingUploadResumeTrigger(
            imageRepository: imageRepository
        )
    }

    /// Crashlytics를 켜고(가능하면) Amplitude 기반 `Analytics`를 만든다.
    ///
    /// Firebase 설정 파일(`GoogleService-Info.plist`)이나 Amplitude API Key가
    /// 빌드에 포함돼 있지 않으면 해당 기능만 조용히 비활성된다 — 키 없이도
    /// 앱은 정상 동작한다.
    private static func makeAnonymousStoreURL() -> URL {
        do {
            let appSupport = try FileManager.default.url(
                for: .applicationSupportDirectory, in: .userDomainMask,
                appropriateFor: nil, create: true
            )
            return appSupport.appendingPathComponent("anonymous.sqlite")
        } catch {
            fatalError("AppEnvironment: Application Support 디렉터리 접근 실패: \(error)")
        }
    }

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
