import Foundation
import FirebaseCore
import FirebaseCrashlytics
import AnalyticsInterface

/// 분석/로깅 SDK의 조립 지점. App composition root에서 한 번만 호출한다.
///
/// Firebase(Crashlytics)와 Amplitude는 서로 독립적인 기능이므로 따로 노출한다.
/// 어느 쪽이든 설정(plist / API Key)이 없으면 해당 기능만 비활성되고 나머지는
/// 정상 동작한다. Firebase·Amplitude SDK 의존은 이 모듈 안에만 갇혀 있어,
/// App·Feature 레이어는 `Analytics` 프로토콜만 바라본다.
public enum AnalyticsBootstrap {

    /// Crashlytics 크래시 수집을 시작한다.
    ///
    /// `FirebaseApp.configure()`는 번들의 `GoogleService-Info.plist`를 읽으므로,
    /// 호출 전에 해당 파일이 앱 리소스에 포함돼 있는지 확인해야 한다.
    public static func startCrashReporting() {
        FirebaseApp.configure()

        // Debug 빌드의 크래시는 실사용 지표를 오염시키므로 수집하지 않는다.
        #if DEBUG
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        #else
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        #endif
    }

    /// Amplitude 기반 `Analytics` 구현을 만든다.
    /// - Parameter amplitudeAPIKey: Amplitude 프로젝트 API Key.
    public static func makeAnalytics(amplitudeAPIKey: String) -> Analytics {
        AmplitudeAnalytics(apiKey: amplitudeAPIKey)
    }

    /// 분석 비활성(테스트·프리뷰·키 부재) 시 사용할 no-op 구현.
    public static func makeNoOpAnalytics() -> Analytics {
        NoOpAnalytics()
    }
}
