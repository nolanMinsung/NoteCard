import AnalyticsInterface
import FirebaseAnalytics
import Foundation

/// Firebase Analytics SDK 를 감싼 `Analytics` 구현. Amplitude 와 함께 `CompositeAnalytics`
/// 로 묶여 동일 이벤트가 두 dashboard 모두에 도착하도록 한다.
///
/// `FirebaseApp.configure()` 가 먼저 호출되어 있어야 한다 (AnalyticsBootstrap.startCrashReporting).
/// Configure 가 안 되어 있으면 `Analytics.logEvent` 가 내부적으로 no-op 처리된다.
public final class FirebaseEventAnalytics: AnalyticsInterface.Analytics, @unchecked Sendable {

    public init() {}

    // FirebaseAnalytics 모듈에도 `Analytics` 타입이 있어 모듈명으로 한정한다.
    public func log(_ event: AnalyticsInterface.AnalyticsEvent) {
        FirebaseAnalytics.Analytics.logEvent(event.name, parameters: event.properties)
    }

    public func setUserId(_ userId: String?) {
        FirebaseAnalytics.Analytics.setUserID(userId)
    }
}
