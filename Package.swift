// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StackAuth",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "StackAuth",
            targets: ["StackAuth"]),
        .executable(
            name: "StackAuthExample",
            targets: ["StackAuthExample"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "StackAuth",
            dependencies: []),
        .executableTarget(
            name: "StackAuthExample",
            dependencies: ["StackAuth"]),
        .testTarget(
            name: "StackAuthTests",
            dependencies: ["StackAuth"]),
    ]
)
