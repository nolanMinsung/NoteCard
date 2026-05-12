import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    .shared,
    product: .staticFramework,
    sources: ["Sources/**"],
    resources: ["Resources/**"],
    dependencies: []
)
