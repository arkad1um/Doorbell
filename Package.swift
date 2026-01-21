// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Doorbell",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Doorbell",
            targets: ["Doorbell"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Doorbell",
            path: "Sources",
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "DoorbellTests",
            dependencies: ["Doorbell"],
            path: "Tests"
        )
    ]
)
