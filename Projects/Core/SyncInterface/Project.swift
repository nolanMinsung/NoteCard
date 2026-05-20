import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    .syncInterface,
    product: .staticFramework,
    sources: ["Sources/**"],
    resources: nil,
    dependencies: [
        .module(.shared),
    ]
)
