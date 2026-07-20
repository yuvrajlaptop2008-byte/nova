// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "NovaKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
    ],
    products: [
        .library(name: "NovaProtocol", targets: ["NovaProtocol"]),
        .library(name: "NovaNativeState", targets: ["NovaNativeState"]),
        .library(name: "NovaKit", targets: ["NovaKit"]),
        .library(name: "NovaChatUI", targets: ["NovaChatUI"]),
    ],
    traits: [
        .trait(name: "Talk", description: "ElevenLabs cloud TTS / talk support"),
        .default(enabledTraits: ["Talk"]),
    ],
    dependencies: [
        .package(url: "https://github.com/steipete/ElevenLabsKit", exact: "0.1.1"),
        .package(url: "https://github.com/groue/GRDB.swift.git", exact: "7.11.1"),
        .package(url: "https://github.com/mgriebling/SwiftMath", exact: "1.7.3"),
        .package(url: "https://github.com/swiftlang/swift-markdown", exact: "0.8.0"),
    ],
    targets: [
        .target(
            name: "NovaProtocol",
            path: "Sources/NovaProtocol",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "NovaNativeState",
            path: "Sources/NovaNativeState",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "NovaKit",
            dependencies: [
                "NovaNativeState",
                "NovaProtocol",
                .product(
                    name: "ElevenLabsKit",
                    package: "ElevenLabsKit",
                    condition: .when(platforms: [.iOS, .macOS], traits: ["Talk"])),
            ],
            path: "Sources/NovaKit",
            resources: [
                .process("Resources"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "NovaChatUI",
            dependencies: [
                "NovaKit",
                "NovaProtocol",
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "SwiftMath", package: "SwiftMath"),
            ],
            path: "Sources/NovaChatUI",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .testTarget(
            name: "NovaKitTests",
            dependencies: [
                "NovaKit",
                "NovaChatUI",
                "NovaProtocol",
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Tests/NovaKitTests",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("SwiftTesting"),
            ]),
        .testTarget(
            name: "NovaNativeStateTests",
            dependencies: ["NovaNativeState"],
            path: "Tests/NovaNativeStateTests",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("SwiftTesting"),
            ]),
    ])
