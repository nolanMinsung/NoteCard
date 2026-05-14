import ProjectDescription

let appName = "NoteCard"
let engAppName = "NoteCard-Eng"
let bundleIdProd = "com.minsung.NoteCard"
let bundleIdEng = "com.minsung.NoteCard.eng"
let developmentTeam = "548W892M42"
let deploymentTarget: DeploymentTargets = .iOS("15.0")

let infoPlistKeys: SettingsDictionary = [
    "INFOPLIST_KEY_CFBundleDisplayName": "$(APP_DISPLAY_NAME)",
    "INFOPLIST_KEY_ITSAppUsesNonExemptEncryption": "NO",
    "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.productivity",
    "INFOPLIST_KEY_LSSupportsOpeningDocumentsInPlace": "NO",
    "INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription": "포토 라이브러리 쓰기 권한 요청",
    "INFOPLIST_KEY_NSPhotoLibraryUsageDescription": "포토 라이브러리 읽기 권한 요청",
    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
    "INFOPLIST_KEY_UILaunchStoryboardName": "LaunchScreen",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations": "UIInterfaceOrientationPortrait",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad":
        "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown",
    "INFOPLIST_KEY_UISupportsDocumentBrowser": "NO",
]

let projectBaseSettings: SettingsDictionary = [
    "DEVELOPMENT_TEAM": .string(developmentTeam),
    "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": "1,2",
]

let appTargetBaseSettings: SettingsDictionary = infoPlistKeys.merging([
    "GENERATE_INFOPLIST_FILE": "YES",
    "IPHONEOS_DEPLOYMENT_TARGET": "15.0",
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
    "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS": "YES",
    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
])

let appResources: ResourceFileElements = [
    "NoteCard/Assets.xcassets",
    "NoteCard/Base.lproj/LaunchScreen.storyboard",
    "NoteCard/Base.lproj/Main.storyboard",
    "NoteCard/ko.lproj/**",
    "NoteCard/en.lproj/**",
]

let appSources: SourceFilesList = ["NoteCard/**/*.swift"]

let appDependencies: [TargetDependency] = [
    .external(name: "Wisp"),
    .project(target: "Shared", path: .relativeToRoot("Projects/Core/Shared")),
    .project(target: "DesignSystem", path: .relativeToRoot("Projects/Core/DesignSystem")),
    .project(target: "Domain", path: .relativeToRoot("Projects/Domain")),
    .project(target: "Data", path: .relativeToRoot("Projects/Data")),
    .project(target: "AnalyticsInterface", path: .relativeToRoot("Projects/Core/AnalyticsInterface")),
    .project(target: "AnalyticsImpl", path: .relativeToRoot("Projects/Core/AnalyticsImpl")),
]

let project = Project(
    name: appName,
    organizationName: "Minsung Kim",
    options: .options(
        automaticSchemesOptions: .disabled,
        defaultKnownRegions: ["en", "ko", "Base"],
        developmentRegion: "ko"
    ),
    settings: .settings(
        base: projectBaseSettings,
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release"),
        ],
        defaultSettings: .recommended
    ),
    targets: [

        // ── 기본 앱 타겟 (한국 / 글로벌 App Store 출시) ───────────────────
        .target(
            name: appName,
            destinations: .iOS,
            product: .app,
            bundleId: bundleIdProd,
            deploymentTargets: deploymentTarget,
            infoPlist: .file(path: "NoteCard/Info.plist"),
            sources: appSources,
            resources: appResources,
            dependencies: appDependencies,
            settings: .settings(
                base: appTargetBaseSettings,
                configurations: [
                    .debug(name: "Debug", settings: [
                        "APP_DISPLAY_NAME": "NoteCard(Dev)",
                        "CODE_SIGN_STYLE": "Automatic",
                        "PROVISIONING_PROFILE_SPECIFIER": "",
                    ], xcconfig: "Configs/Version.xcconfig"),
                    .release(name: "Release", settings: [
                        "APP_DISPLAY_NAME": "NoteCard",
                        "CODE_SIGN_STYLE": "Manual",
                        "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.minsung.NoteCard",
                    ], xcconfig: "Configs/Version.xcconfig"),
                ]
            )
        ),

        // ── 영어 스크린샷 촬영용 타겟 ────────────────────────────────────
        // 같은 sources / resources를 공유하되 bundle id만 다르게 두어 시뮬레이터에
        // NoteCard와 함께 별도 앱으로 설치된다 (= 데이터 sandbox 분리).
        // App Store 출시 대상 아님 — Debug/Release 둘 다 Automatic signing.
        .target(
            name: engAppName,
            destinations: .iOS,
            product: .app,
            bundleId: bundleIdEng,
            deploymentTargets: deploymentTarget,
            infoPlist: .file(path: "NoteCard/Info.plist"),
            sources: appSources,
            resources: appResources,
            dependencies: appDependencies,
            settings: .settings(
                base: appTargetBaseSettings,
                configurations: [
                    .debug(name: "Debug", settings: [
                        "APP_DISPLAY_NAME": "NoteCard-Eng",
                        "CODE_SIGN_STYLE": "Automatic",
                        "PROVISIONING_PROFILE_SPECIFIER": "",
                    ], xcconfig: "Configs/Version.xcconfig"),
                    .release(name: "Release", settings: [
                        "APP_DISPLAY_NAME": "NoteCard-Eng",
                        "CODE_SIGN_STYLE": "Automatic",
                        "PROVISIONING_PROFILE_SPECIFIER": "",
                    ], xcconfig: "Configs/Version.xcconfig"),
                ]
            )
        ),

        // ── Unit Tests (기본 앱 타겟 대상) ───────────────────────────────
        .target(
            name: "\(appName)Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.minsung.NoteCardTests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            sources: ["Tests/AppTests/**/*.swift"],
            dependencies: [
                .target(name: appName),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: appName,
            shared: true,
            buildAction: .buildAction(targets: ["\(appName)"]),
            testAction: .targets(["\(appName)Tests"]),
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        ),
        .scheme(
            name: engAppName,
            shared: true,
            buildAction: .buildAction(targets: [.target(engAppName)]),
            testAction: nil,
            runAction: .runAction(configuration: "Debug"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        ),
    ]
)
