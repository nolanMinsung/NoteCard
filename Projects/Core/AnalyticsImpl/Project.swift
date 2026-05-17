import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    .analyticsImpl,
    product: .staticFramework,
    sources: ["Sources/**"],
    resources: nil,
    dependencies: [
        .module(.analyticsInterface),
        .external(name: "FirebaseCrashlytics"),
        .external(name: "FirebaseAnalytics"),
        .external(name: "AmplitudeSwift"),
    ]
)
