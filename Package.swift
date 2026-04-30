// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "swift-tagged-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "Tagged Primitives",
            targets: ["Tagged Primitives"]
        ),
        .library(
            name: "Tagged Primitives Standard Library Integration",
            targets: ["Tagged Primitives Standard Library Integration"]
        ),
        .library(
            name: "Tagged Primitives Test Support",
            targets: ["Tagged Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-carrier-primitives.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Tagged Primitives",
            dependencies: [
                .product(name: "Carrier Primitives", package: "swift-carrier-primitives"),
            ]
        ),
        .target(
            name: "Tagged Primitives Standard Library Integration",
            dependencies: [
                "Tagged Primitives",
            ]
        ),
        .target(
            name: "Tagged Primitives Test Support",
            dependencies: [
                "Tagged Primitives",
                "Tagged Primitives Standard Library Integration",
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Tagged Primitives Tests",
            dependencies: [
                "Tagged Primitives",
                "Tagged Primitives Standard Library Integration",
                "Tagged Primitives Test Support",
                .product(name: "Carrier Primitives", package: "swift-carrier-primitives"),
                .product(name: "Carrier Primitives Standard Library Integration", package: "swift-carrier-primitives"),
            ]
        ),
        .testTarget(
            name: "Tagged Primitives Standard Library Integration Tests",
            dependencies: [
                "Tagged Primitives",
                "Tagged Primitives Standard Library Integration",
                "Tagged Primitives Test Support",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
