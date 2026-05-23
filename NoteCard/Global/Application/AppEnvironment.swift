//
//  AppEnvironment.swift
//  NoteCard
//

import Foundation
import Data
import Domain
import AnalyticsInterface
import AnalyticsImpl

/// 앱 전체에서 공유되는 의존성 묶음.
///
/// 프로세스 수명 동안 단 하나만 생성되어 `AppDelegate`가 소유하고,
/// `SceneDelegate`를 거쳐 화면 계층으로 생성자 주입된다.
/// Repository 구현체는 모두 같은 `CoreDataStack` 인스턴스를 공유하므로,
/// Combine publisher 이벤트도 화면 간에 끊김 없이 전달된다.
struct AppEnvironment {

    let coreDataStack: CoreDataStack
    let memoRepository: MemoRepository
    let categoryRepository: CategoryRepository
    let imageRepository: ImageRepository
    let analytics: Analytics

    private let dataLayer: UserScopedDataLayer

    init() {
        // 인증 인프라는 별도 브랜치라 현재는 익명 사용자만 존재한다.
        let userIDProvider = AnonymousUserIDProvider()

        // 데이터 레이어가 익명 store를 열기 전에 레거시 데이터를 이전한다 (1회, 멱등).
        // 실패 시 Debug 빌드에선 즉시 trap, Release 빌드에선 no-op이 되어 다음 실행에 재시도된다.
        // TODO: Crashlytics non-fatal로 prod 가시성 확보 — onError 클로저는 그 의존성 주입을 위한 자리.
        LegacyStoreMigrator.migrateIfNeeded(
            anonymousStoreURL: UserScopedDataLayer.anonymousStoreURL(),
            onError: { error in assertionFailure("LegacyStoreMigrator 실패: \(error)") }
        )

        let dataLayer = UserScopedDataLayer(userIDProvider: userIDProvider)
        self.dataLayer = dataLayer

        let coreDataStack = dataLayer.currentStack
        self.coreDataStack = coreDataStack
        let memoRepository = MemoRepositoryImpl(stack: coreDataStack)
        self.memoRepository = memoRepository
        self.categoryRepository = CategoryRepositoryImpl(stack: coreDataStack)
        self.imageRepository = ImageRepositoryImpl(stack: coreDataStack, memoRepository: memoRepository)
        self.analytics = Self.setUpAnalytics()
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
