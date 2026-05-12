import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    .designSystem,
    product: .staticFramework,
    sources: ["Sources/**"],
    resources: nil,
    dependencies: []
)
