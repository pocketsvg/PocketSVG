// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "PocketSVG",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v8),
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
            path: "Sources"
        ),
        .testTarget(
            name: "PocketSVGTests",
            dependencies: ["PocketSVG"],
            path: "Tests"
        )
    ],
    cxxLanguageStandard: .cxx14
)
