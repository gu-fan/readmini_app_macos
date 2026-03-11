// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ReadMiniMacOS",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "ReadMiniMacOS",
            targets: ["ReadMiniMacOS"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "ReadMiniMacOS"
        ),
        .testTarget(
            name: "ReadMiniMacOSTests",
            dependencies: ["ReadMiniMacOS"]
        ),
    ]
)
