import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
    .settingsFeature,
    resources: ["Resources/**"],
    additionalDependencies: [
        .module(.syncInterface),
    ]
)
