// swift-tools-version:5.9

import PackageDescription

let supportedPlatforms: [SupportedPlatform] = [
    .macOS(.v10_13),
    .iOS(.v12),
    .tvOS(.v12),
    .watchOS(.v4),
    .visionOS(.v1),
]

let packageProducts: [Product] = [
    .library(
        name: "PocketSVG",
        type: .static,
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
