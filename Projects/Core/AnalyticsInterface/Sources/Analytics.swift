import Foundation

/// 외부 분석 SDK(예: Amplitude, Firebase Analytics) 통합 지점을 추상화하는 인터페이스.
/// 구현체는 별도 모듈(AnalyticsImpl)에 두고, App composition root에서만 인스턴스를
/// 만들어 의존 주입한다.
public protocol Analytics: AnyObject, Sendable {
    func log(_ event: AnalyticsEvent)

    /// 사용자 식별자 설정. sign-in 시점에 Firebase UID 를 넘기면 그 이후 이벤트가 같은
    /// user_id 로 묶이고, 익명 시기의 device_id 와도 identity merge 가능. sign-out 시
    /// `nil` 을 넘겨 익명 사용자로 되돌린다.
    func setUserId(_ userId: String?)
}

public struct AnalyticsEvent: Sendable, Hashable {
    public let name: String
    public let properties: [String: String]

    public init(name: String, properties: [String: String] = [:]) {
        self.name = name
        self.properties = properties
    }
}
