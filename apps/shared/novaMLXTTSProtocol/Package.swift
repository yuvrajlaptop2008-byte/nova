// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "NovaMLXTTSProtocol",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "NovaMLXTTSProtocol", targets: ["NovaMLXTTSProtocol"]),
    ],
    targets: [
        .target(name: "NovaMLXTTSProtocol"),
        .testTarget(
            name: "NovaMLXTTSProtocolTests",
            dependencies: ["NovaMLXTTSProtocol"]),
    ])
