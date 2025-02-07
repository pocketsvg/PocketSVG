// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "PocketSVG",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v9),
        .tvOS(.v10),
        .watchOS(.v3),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "PocketSVG",
            type: .dynamic,
            targets: ["PocketSVG"])
    ],
    targets: [
        .target(
            name: "PocketSVG",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "PocketSVGTests",
            dependencies: ["PocketSVG"],
            path: "Tests",
            resources: [
                .process("Resources"),
            ]
        ),
    ],
    cxxLanguageStandard: .cxx14
)
