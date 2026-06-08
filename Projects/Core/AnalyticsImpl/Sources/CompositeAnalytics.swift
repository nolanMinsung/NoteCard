import AnalyticsInterface
import Foundation

/// 여러 `Analytics` 구현체에 동일 호출을 fan-out 한다. 호출 측은 한 인스턴스만 들고 있어도
/// Amplitude·Firebase Analytics 등 여러 dashboard 에 동시에 보낼 수 있다.
///
/// 순서 보장은 등록된 배열 순서. 한 구현체에서 에러가 발생해도 다른 구현체로의 전파는 보존
/// 하기 위해 그냥 호출만 한다 (현 시점 구현체들은 throws 없음).
public final class CompositeAnalytics: Analytics, @unchecked Sendable {

    private let underlying: [Analytics]

    public init(_ underlying: [Analytics]) {
        self.underlying = underlying
    }

    public func log(_ event: AnalyticsEvent) {
        for analytics in underlying {
            analytics.log(event)
        }
    }

    public func setUserId(_ userId: String?) {
        for analytics in underlying {
            analytics.setUserId(userId)
        }
    }
}
