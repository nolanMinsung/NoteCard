import Foundation
import AnalyticsInterface

/// 분석을 비활성화하는 no-op 구현. 모든 이벤트를 버린다.
///
/// Amplitude API 키가 없는 환경(CI 빌드, Secrets 미설정 등)에서
/// `AppEnvironment`가 fallback으로 사용한다.
public final class NoOpAnalytics: Analytics, @unchecked Sendable {
    public init() {}

    public func log(_ event: AnalyticsEvent) {
        // 이벤트를 의도적으로 버린다.
    }
}
