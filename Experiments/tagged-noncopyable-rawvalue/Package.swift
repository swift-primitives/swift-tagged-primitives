// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "tagged-noncopyable-rawvalue",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(path: "../.."),
        .package(path: "../../../swift-equation-primitives"),
        .package(path: "../../../swift-comparison-primitives"),
        .package(path: "../../../swift-hash-primitives"),
    ],
    targets: [
        .executableTarget(
            name: "tagged-noncopyable-rawvalue",
            dependencies: [
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
                .product(name: "Equation Primitives", package: "swift-equation-primitives"),
                .product(name: "Comparison Primitives", package: "swift-comparison-primitives"),
                .product(name: "Hash Primitives", package: "swift-hash-primitives"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("Lifetimes"),
            ]
        )
    ]
)
