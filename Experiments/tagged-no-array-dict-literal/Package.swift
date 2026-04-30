// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "tagged-no-array-dict-literal",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "tagged-no-array-dict-literal",
            dependencies: [
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
                .product(name: "Tagged Primitives Standard Library Integration", package: "swift-tagged-primitives"),
            ]
        ),
    ]
)
