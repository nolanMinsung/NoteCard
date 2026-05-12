import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    .domain,
    product: .staticFramework,
    sources: ["Sources/**"],
    resources: nil,
    dependencies: [
        .module(.shared),
    ],
    hasTests: true
)
