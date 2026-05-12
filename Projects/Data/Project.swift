import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    .data,
    product: .staticFramework,
    sources: ["Sources/**"],
    // .xcdatamodeld와 .xcmappingmodel은 같은 번들에 함께 있어야 NSMigrationManager가
    // 자동 검색하므로 두 패턴을 모두 명시. Phase 7 plan의 결정적 주의사항 #3.
    resources: [
        "Sources/CoreData/**/*.xcdatamodeld",
        "Sources/CoreData/**/*.xcmappingmodel",
    ],
    dependencies: [
        .module(.domain),
        .module(.shared),
    ],
    hasTests: true
)
