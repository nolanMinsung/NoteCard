import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    .syncImpl,
    product: .staticFramework,
    sources: ["Sources/**"],
    resources: nil,
    dependencies: [
        .module(.syncInterface),
        .module(.domain),
        .external(name: "FirebaseAuth"),
    ]
)
