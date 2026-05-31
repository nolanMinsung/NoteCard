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
        .module(.data),
        .external(name: "FirebaseAuth"),
        .external(name: "FirebaseFirestore"),
        .external(name: "FirebaseStorage"),
    ],
    hasTests: true
)
