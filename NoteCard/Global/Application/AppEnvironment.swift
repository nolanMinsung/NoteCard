//
//  AppEnvironment.swift
//  NoteCard
//

import Foundation
import Data
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
    let memoRepository: MemoRepositoryImpl
    let categoryRepository: CategoryRepositoryImpl
    let imageRepository: ImageRepositoryImpl
    let analytics: Analytics

    init() {
        let coreDataStack = CoreDataStack()
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
