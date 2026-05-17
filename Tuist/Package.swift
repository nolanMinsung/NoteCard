// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "Wisp": .staticFramework,
        "FirebaseCrashlytics": .staticFramework,
        "FirebaseAnalytics": .staticFramework,
        "AmplitudeSwift": .staticFramework,
    ]
)
#endif

let package = Package(
    name: "NoteCard",
    dependencies: [
        .package(url: "https://github.com/WispKit/Wisp.git", from: "1.10.1"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0"),
        .package(url: "https://github.com/amplitude/Amplitude-Swift.git", from: "1.0.0"),
    ]
)
