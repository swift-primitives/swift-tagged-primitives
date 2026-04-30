// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "tagged-no-dynamicmemberlookup",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "tagged-no-dynamicmemberlookup",
            dependencies: [
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
            ]
        ),
    ]
)
