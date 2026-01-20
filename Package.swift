// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-outdated",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "swift-outdated", targets: ["swift-outdated"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/tuist/XcodeProj.git", from: "8.0.0")
    ],
    targets: [
        .executableTarget(
            name: "swift-outdated",
            dependencies: [
                "SwiftOutdatedCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "SwiftOutdatedCore",
            dependencies: [
                .product(name: "XcodeProj", package: "XcodeProj")
            ]
        ),
        .testTarget(
            name: "SwiftOutdatedCoreTests",
            dependencies: ["SwiftOutdatedCore"]
        )
    ]
)
