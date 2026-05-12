import Foundation

/// Shared 모듈의 리소스 번들 접근자.
/// `Localizable.xcstrings` 등을 호출부에서 명시적으로 사용할 때 쓴다.
public enum SharedResources {
    public static let bundle: Bundle = .module
}
