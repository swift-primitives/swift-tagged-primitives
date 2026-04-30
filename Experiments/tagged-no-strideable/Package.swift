// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "tagged-no-strideable",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "tagged-no-strideable",
            dependencies: [
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
            ]
        ),
    ]
)
