import ProjectDescription

let appName = "NoteCard"
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

let project = Project(
    name: appName,
    organizationName: "Minsung Kim",
    options: .options(
        defaultKnownRegions: ["en", "ko", "Base"],
        developmentRegion: "ko"
    ),
    settings: .settings(
        base: projectBaseSettings,
        configurations: [
            .debug(name: "Debug", settings: ["APP_DISPLAY_NAME": "NoteCard"]),
            .release(name: "Release", settings: ["APP_DISPLAY_NAME": "NoteCard"]),
            .debug(name: "DebugEng", settings: ["APP_DISPLAY_NAME": "NoteCard(Dev)"]),
            .release(name: "ReleaseEng", settings: ["APP_DISPLAY_NAME": "NoteCard-Eng"]),
        ],
        defaultSettings: .recommended
    ),
    targets: [
        .target(
            name: appName,
            destinations: .iOS,
            product: .app,
            bundleId: "$(APP_BUNDLE_ID)",
            deploymentTargets: deploymentTarget,
            infoPlist: .file(path: "NoteCard/Info.plist"),
            sources: [
                "NoteCard/**/*.swift",
            ],
            resources: [
                "NoteCard/Assets.xcassets",
                "NoteCard/Base.lproj/LaunchScreen.storyboard",
                "NoteCard/Base.lproj/Main.storyboard",
                "NoteCard/ko.lproj/**",
                "NoteCard/en.lproj/**",
            ],
            dependencies: [
                .external(name: "Wisp"),
                .project(target: "Shared", path: .relativeToRoot("Projects/Core/Shared")),
                .project(target: "DesignSystem", path: .relativeToRoot("Projects/Core/DesignSystem")),
                .project(target: "Domain", path: .relativeToRoot("Projects/Domain")),
                .project(target: "Data", path: .relativeToRoot("Projects/Data")),
            ],
            settings: .settings(
                base: infoPlistKeys.merging([
                    "GENERATE_INFOPLIST_FILE": "YES",
                    "IPHONEOS_DEPLOYMENT_TARGET": "15.0",
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
                    "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS": "YES",
                    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
                ]),
                configurations: [
                    .debug(name: "Debug", settings: [
                        "APP_BUNDLE_ID": .string(bundleIdProd),
                        "CODE_SIGN_STYLE": "Automatic",
                        "PROVISIONING_PROFILE_SPECIFIER": "",
                    ], xcconfig: "Configs/Version.xcconfig"),
                    .release(name: "Release", settings: [
                        "APP_BUNDLE_ID": .string(bundleIdProd),
                        "CODE_SIGN_STYLE": "Manual",
                        "PROVISIONING_PROFILE_SPECIFIER": "match AppStore com.minsung.NoteCard",
                    ], xcconfig: "Configs/Version.xcconfig"),
                    .debug(name: "DebugEng", settings: [
                        "APP_BUNDLE_ID": .string(bundleIdEng),
                        "CODE_SIGN_STYLE": "Automatic",
                        "PROVISIONING_PROFILE_SPECIFIER": "",
                    ], xcconfig: "Configs/Version.xcconfig"),
                    .release(name: "ReleaseEng", settings: [
                        "APP_BUNDLE_ID": .string(bundleIdEng),
                        "CODE_SIGN_STYLE": "Automatic",
                        "PROVISIONING_PROFILE_SPECIFIER": "",
                    ], xcconfig: "Configs/Version.xcconfig"),
                ]
            )
        ),
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
            name: "\(appName)-Eng",
            shared: true,
            buildAction: .buildAction(targets: ["\(appName)"]),
            testAction: nil,
            runAction: .runAction(configuration: "DebugEng"),
            archiveAction: .archiveAction(configuration: "ReleaseEng"),
            profileAction: .profileAction(configuration: "ReleaseEng"),
            analyzeAction: .analyzeAction(configuration: "DebugEng")
        ),
    ]
)
