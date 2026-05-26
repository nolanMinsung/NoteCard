import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
    .loginFeature,
    additionalDependencies: [
        .module(.syncInterface),
    ]
)
