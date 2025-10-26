// swift-tools-version:5.9

import PackageDescription

let supportedPlatforms: [SupportedPlatform] = [
    .macOS(.v10_10),
    .iOS(.v9),
    .tvOS(.v10),
    .watchOS(.v3),
    .visionOS(.v1),
]

let packageProducts: [Product] = [
    .library(
        name: "PocketSVG",
        type: .dynamic,
        targets: ["PocketSVG"]
    ),
]

let packageTargets: [Target] = [
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
]

#if swift(>=6.0)
let package = Package(
    name: "PocketSVG",
    platforms: supportedPlatforms,
    products: packageProducts,
    targets: packageTargets,
    swiftLanguageModes: [.v5],
    cxxLanguageStandard: .cxx14
)
#else
let package = Package(
    name: "PocketSVG",
    platforms: supportedPlatforms,
    products: packageProducts,
    targets: packageTargets,
    swiftLanguageVersions: [.v5],
    cxxLanguageStandard: .cxx14
)
#endif
