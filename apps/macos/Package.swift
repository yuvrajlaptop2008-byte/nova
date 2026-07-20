// swift-tools-version: 6.2
// Package manifest for the Nova macOS companion (menu bar app + IPC library).

import PackageDescription

let package = Package(
    name: "Nova",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "NovaIPC", targets: ["NovaIPC"]),
        .library(name: "NovaDiscovery", targets: ["NovaDiscovery"]),
        .executable(name: "Nova", targets: ["Nova"]),
        .executable(name: "nova-mac", targets: ["NovaMacCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", exact: "3.0.1"),
        .package(url: "https://github.com/orchetect/MenuBarExtraAccess", exact: "1.3.0"),
        .package(url: "https://github.com/swiftlang/swift-subprocess.git", from: "0.4.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.12.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.0"),
        .package(url: "https://github.com/steipete/Peekaboo.git", exact: "3.9.3"),
        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.3.1"),
        .package(path: "../shared/NovaKit"),
        .package(path: "../shared/NovaMLXTTSProtocol"),
        .package(path: "../swabble"),
    ],
    targets: [
        .target(
            name: "NovaIPC",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "NovaDiscovery",
            dependencies: [
                .product(name: "NovaKit", package: "NovaKit"),
            ],
            path: "Sources/NovaDiscovery",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .executableTarget(
            name: "Nova",
            dependencies: [
                "NovaIPC",
                "NovaDiscovery",
                .product(name: "NovaNativeState", package: "NovaKit"),
                .product(name: "NovaKit", package: "NovaKit"),
                .product(name: "NovaChatUI", package: "NovaKit"),
                .product(name: "NovaMLXTTSProtocol", package: "NovaMLXTTSProtocol"),
                .product(name: "NovaProtocol", package: "NovaKit"),
                .product(name: "SwabbleKit", package: "swabble"),
                .product(name: "MenuBarExtraAccess", package: "MenuBarExtraAccess"),
                .product(name: "Subprocess", package: "swift-subprocess"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "PeekabooBridge", package: "Peekaboo"),
                .product(name: "PeekabooAutomationKit", package: "Peekaboo"),
                .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ],
            exclude: [
                "Resources/Info.plist",
                "Resources/Localizable.xcstrings",
            ],
            resources: [
                .copy("Resources/Nova.icns"),
                .copy("Resources/DeviceModels"),
                .copy("Resources/ProviderIcons"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .executableTarget(
            name: "NovaMacCLI",
            dependencies: [
                "NovaDiscovery",
                .product(name: "NovaKit", package: "NovaKit"),
                .product(name: "NovaProtocol", package: "NovaKit"),
            ],
            path: "Sources/NovaMacCLI",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .testTarget(
            name: "NovaIPCTests",
            dependencies: [
                "NovaIPC",
                "Nova",
                "NovaMacCLI",
                "NovaDiscovery",
                .product(name: "NovaChatUI", package: "NovaKit"),
                .product(name: "NovaKit", package: "NovaKit"),
                .product(name: "NovaMLXTTSProtocol", package: "NovaMLXTTSProtocol"),
                .product(name: "NovaProtocol", package: "NovaKit"),
                .product(name: "SwabbleKit", package: "swabble"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("SwiftTesting"),
            ]),
    ])
