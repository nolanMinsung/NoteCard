// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "Wisp": .staticFramework,
    ]
)
#endif

let package = Package(
    name: "NoteCard",
    dependencies: [
        .package(url: "https://github.com/WispKit/Wisp.git", from: "1.10.1"),
    ]
)
