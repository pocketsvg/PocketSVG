// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "PocketSVG",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v9),
        .tvOS(.v10),
        .watchOS(.v3)
    ],
    products: [
        .library(
            name: "PocketSVG",
            targets: ["PocketSVG"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "PocketSVG",
            dependencies: [],
            path: "Sources",
            exclude: ["Demos", "ci.sh", "PocketSVG.podspec"],
            resources: [
                .process("SVGColors.plist")
            ]
        ),
        .testTarget(
            name: "PocketSVGTests",
            dependencies: ["PocketSVG"],
            path: "Tests",
            exclude: ["Demos", "ci.sh", "PocketSVG.podspec"],
            resources: [
                .process("SVGColors.plist")
            ]
        )
    ],
    cxxLanguageStandard: .cxx14
)
