import ProjectDescription

/// Clean Architecture 레이어. `Projects/` 하위의 폴더와 1:1 대응.
public enum Layer: String {
    case app          = "Projects/App"
    case presentation = "Projects/Presentation"
    case domain       = "Projects/Domain"
    case data         = "Projects/Data"
    case core         = "Projects/Core"
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
    /// 임시: Presentation 전체를 단일 모듈로 묶음. 추후 HomeFeature / MemoFeature /
    /// SettingsFeature로 sub-split하기 전에는 이 모듈이 모든 화면 코드를 흡수한다.
    case presentation       = "Presentation"

    public var layer: Layer {
        switch self {
        case .domain: return .domain
        case .data:   return .data
        case .designSystem, .shared, .analyticsInterface, .analyticsImpl:
            return .core
        case .homeFeature, .memoFeature, .settingsFeature, .presentation:
            return .presentation
        }
    }

    /// 저장소 루트 기준 모듈 폴더 경로.
    /// Domain / Data / Presentation(단일 모듈일 때)은 레이어 자체가 단일 모듈이므로
    /// 하위 폴더를 두지 않는다. 그 외(Core)는 "<Layer>/<ModuleName>" 형태.
    public var path: String {
        switch self {
        case .domain, .data, .presentation:
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
