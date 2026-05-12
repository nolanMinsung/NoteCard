import Foundation
import ProjectDescription

public extension Project {

    /// 단일 모듈(Project + 1 target, 선택적으로 Tests).
    /// 대부분의 Domain / Data / DesignSystem / Shared / *Feature 모듈에 사용.
    static func module(
        _ module: Module,
        product: Product = .staticFramework,
        sources: SourceFilesList = ["Sources/**"],
        resources: ResourceFileElements? = nil,
        dependencies: [TargetDependency] = [],
        baseSettings: SettingsDictionary = [:],
        hasTests: Bool = false
    ) -> Project {
        let main: Target = .target(
            name: module.rawValue,
            destinations: .iOS,
            product: product,
            bundleId: module.bundleId,
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: sources,
            resources: resources,
            dependencies: dependencies,
            settings: .settings(base: baseSettings)
        )

        var targets: [Target] = [main]
        if hasTests {
            targets.append(
                .target(
                    name: "\(module.rawValue)Tests",
                    destinations: .iOS,
                    product: .unitTests,
                    bundleId: "\(module.bundleId).tests",
                    deploymentTargets: .iOS("15.0"),
                    infoPlist: .default,
                    sources: ["Tests/**"],
                    dependencies: [.target(name: module.rawValue)]
                )
            )
        }
        return Project(name: module.rawValue, targets: targets)
    }

    /// Feature 모듈 전용 팩토리. Domain / DesignSystem / Shared / AnalyticsInterface를
    /// 자동으로 의존성에 포함시켜 호출부의 반복을 줄인다.
    static func feature(
        _ feature: Module,
        sources: SourceFilesList = ["Sources/**"],
        resources: ResourceFileElements? = nil,
        additionalDependencies: [TargetDependency] = [],
        hasTests: Bool = false
    ) -> Project {
        let baseDependencies: [TargetDependency] = [
            .module(.domain),
            .module(.designSystem),
            .module(.shared),
            .module(.analyticsInterface),
        ]
        return Project.module(
            feature,
            sources: sources,
            resources: resources,
            dependencies: baseDependencies + additionalDependencies,
            hasTests: hasTests
        )
    }

    /// Interface / Impl 두 타겟을 한 Project에 동시에 만드는 팩토리.
    /// Analytics 모듈처럼 외부 SDK가 들어올 자리를 추상화할 때만 사용한다.
    static func interfaceImpl(
        interface: Module,
        impl: Module,
        interfaceSources: SourceFilesList = ["Interface/Sources/**"],
        implSources: SourceFilesList = ["Impl/Sources/**"],
        interfaceDependencies: [TargetDependency] = [],
        implDependencies: [TargetDependency] = []
    ) -> Project {
        let interfaceTarget: Target = .target(
            name: interface.rawValue,
            destinations: .iOS,
            product: .staticFramework,
            bundleId: interface.bundleId,
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: interfaceSources,
            dependencies: interfaceDependencies
        )
        let implTarget: Target = .target(
            name: impl.rawValue,
            destinations: .iOS,
            product: .staticFramework,
            bundleId: impl.bundleId,
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: implSources,
            dependencies: [.target(name: interface.rawValue)] + implDependencies
        )
        return Project(
            name: interface.rawValue.replacingOccurrences(of: "Interface", with: ""),
            targets: [interfaceTarget, implTarget]
        )
    }
}
