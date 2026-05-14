import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    .analyticsInterface,
    product: .staticFramework,
    sources: ["Sources/**"],
    resources: nil,
    dependencies: []
)
