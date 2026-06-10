// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SwiftGlow",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "SwiftGlow",
            targets: ["SwiftGlow"]
        ),
        .executable(
            name: "SwiftGlowDemo",
            targets: ["SwiftGlowDemo"]
        )
    ],
    targets: [
        .target(
            name: "SwiftGlow",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "SwiftGlowDemo",
            dependencies: ["SwiftGlow"]
        ),
        .testTarget(
            name: "SwiftGlowTests",
            dependencies: ["SwiftGlow"]
        )
    ]
)
