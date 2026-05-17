import Foundation
import AmplitudeSwift
import AnalyticsInterface

/// Amplitude SDK를 감싼 `Analytics` 구현.
///
/// 제품 이벤트(퍼널·리텐션 분석용)를 Amplitude로 전송한다. Amplitude SDK
/// 의존은 이 타입 안에만 갇혀 있고, App·Feature 레이어는 `Analytics`
/// 프로토콜만 바라본다 — SDK 교체 시 이 파일만 바꾸면 된다.
public final class AmplitudeAnalytics: Analytics, @unchecked Sendable {

    private let amplitude: Amplitude

    public init(apiKey: String) {
        amplitude = Amplitude(configuration: Configuration(apiKey: apiKey))
    }

    // AmplitudeSwift에도 `AnalyticsEvent` 타입이 있어 모듈명으로 한정한다.
    public func log(_ event: AnalyticsInterface.AnalyticsEvent) {
        amplitude.track(eventType: event.name, eventProperties: event.properties)
    }
}
