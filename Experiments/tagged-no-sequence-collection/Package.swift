// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "tagged-no-sequence-collection",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "tagged-no-sequence-collection",
            dependencies: [
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
                .product(name: "Tagged Primitives Standard Library Integration", package: "swift-tagged-primitives"),
            ]
        ),
    ]
)
