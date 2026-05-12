import Foundation

/// Data 모듈의 리소스 번들 접근자.
/// `.xcdatamodeld` (컴파일된 `.momd`)와 `.xcmappingmodel` (컴파일된 `.cdm`)이
/// 이 번들에 함께 들어가 있다.
public enum DataResources {
    public static let bundle: Bundle = .module
}
