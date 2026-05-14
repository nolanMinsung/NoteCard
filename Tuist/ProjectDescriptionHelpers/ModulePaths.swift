import ProjectDescription

/// 모듈러 아키텍처의 레이어. `Projects/` 하위의 폴더와 1:1 대응.
///
/// 명명 메모: 일반적으로 "Presentation"이라 불리는 UI 레이어를 여기서는 `feature`로
/// 둔다. 사용자 가치 단위(UI든 비-UI든)를 포괄적으로 담기 위함. Widget / App Intents /
/// Spotlight 같은 비-UI 기능이 같은 도메인 안에 추가되어도 같은 모듈에 자연스레 흡수.
public enum Layer: String {
    case app     = "Projects/App"
    case feature = "Projects/Feature"
    case domain  = "Projects/Domain"
    case data    = "Projects/Data"
    case core    = "Projects/Core"
}

/// 모듈 이름과 거주 레이어를 한 곳에서 관리.
public enum Module: String {
    case domain             = "Domain"
    case data               = "Data"
    case designSystem       = "DesignSystem"
    case shared             = "Shared"
    case analyticsInterface = "AnalyticsInterface"
    case analyticsImpl      = "AnalyticsImpl"
    case homeFeature        = "HomeFeature"
    case memoFeature        = "MemoFeature"
    case settingsFeature    = "SettingsFeature"

    public var layer: Layer {
        switch self {
        case .domain: return .domain
        case .data:   return .data
        case .designSystem, .shared, .analyticsInterface, .analyticsImpl:
            return .core
        case .homeFeature, .memoFeature, .settingsFeature:
            return .feature
        }
    }

    /// 저장소 루트 기준 모듈 폴더 경로.
    /// Domain / Data는 레이어 자체가 단일 모듈이므로 하위 폴더를 두지 않는다.
    /// 그 외(Core, Feature)는 "<Layer>/<ModuleName>" 형태.
    public var path: String {
        switch self {
        case .domain, .data:
            return layer.rawValue
        default:
            return "\(layer.rawValue)/\(rawValue)"
        }
    }

    /// 외부 SPM 의존성과 충돌하지 않도록 모듈별로 고유한 bundle id.
    public var bundleId: String { "com.minsung.NoteCard.\(rawValue)" }
}

public extension TargetDependency {
    /// `Module` enum을 그대로 의존성으로 변환.
    static func module(_ module: Module) -> TargetDependency {
        .project(target: module.rawValue, path: .relativeToRoot(module.path))
    }
}
