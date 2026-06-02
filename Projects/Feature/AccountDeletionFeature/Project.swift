import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
    .accountDeletionFeature,
    additionalDependencies: [
        .module(.syncInterface),
    ]
)
