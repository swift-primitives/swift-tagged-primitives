// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "tagged-no-rawrepresentable",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(path: "../.."),
        .package(path: "../../../swift-carrier-primitives"),
    ],
    targets: [
        .executableTarget(
            name: "tagged-no-rawrepresentable",
            dependencies: [
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
                .product(name: "Carrier Primitives Standard Library Integration", package: "swift-carrier-primitives"),
            ]
        ),
    ]
)
