// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "SmithCore",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SmithCore",
            targets: ["SmithCore"]),
    ],
    targets: [
        .target(
            name: "SmithCore",
            path: "Sources/SmithCore"
        ),
        .testTarget(
            name: "SmithCoreTests",
            dependencies: ["SmithCore"],
            path: "Tests/SmithCoreTests"
        ),
    ]
)
