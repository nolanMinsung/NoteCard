import Foundation
import AnalyticsInterface

/// 분석 SDK가 아직 통합되기 전의 placeholder 구현. 모든 이벤트를 버린다.
/// Sentry / Amplitude / Firebase 등 SDK를 도입할 때 이 자리에서 wrapping.
public final class NoOpAnalytics: Analytics, @unchecked Sendable {
    public init() {}

    public func log(_ event: AnalyticsEvent) {
        // No-op. SDK 통합 시 여기에서 forwarding.
    }
}
