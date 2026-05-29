// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SorryBuddy",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SorryBuddy", targets: ["SorryBuddy"]),
        .library(name: "SorryBuddyCore", targets: ["SorryBuddyCore"])
    ],
    targets: [
        .target(
            name: "SorryBuddyCore",
            linkerSettings: [
                .unsafeFlags(["-F", "/System/Library/PrivateFrameworks"]),
                .linkedFramework("DisplayServices")
            ]),
        .executableTarget(
            name: "SorryBuddy",
            dependencies: ["SorryBuddyCore"]),
        .testTarget(
            name: "SorryBuddyCoreTests",
            dependencies: ["SorryBuddyCore"])
    ]
)
