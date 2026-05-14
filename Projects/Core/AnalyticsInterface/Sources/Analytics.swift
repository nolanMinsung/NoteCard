import Foundation

/// 외부 분석 SDK(예: Sentry, Crashlytics, Amplitude) 통합 지점을 추상화하는 인터페이스.
/// 구현체는 별도 모듈(AnalyticsImpl)에 두고, App composition root에서만 인스턴스를
/// 만들어 의존 주입한다.
public protocol Analytics: AnyObject, Sendable {
    func log(_ event: AnalyticsEvent)
}

public struct AnalyticsEvent: Sendable, Hashable {
    public let name: String
    public let properties: [String: String]

    public init(name: String, properties: [String: String] = [:]) {
        self.name = name
        self.properties = properties
    }
}
