// swift-tools-version: 6.3.1

// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-tagged-primitives open source project
//
// Copyright (c) 2026 Coen ten Thije Boonkkamp and the swift-tagged-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

// PoC of the Lint/ nested-package mechanism (architecture cohort Phase A).
//
// This nested SwiftPM package replaces the consumer's single-file
// `Lint.swift` with a real package that links the swift-linter engine,
// the institute-canonical rule packs, AND a domain-aware custom rule
// (Linter Rule Tagged Domain Audit) that imports `Tagged Primitives`
// from the parent package.
//
// The executable target `Lint` IS the linter binary for this consumer:
// it composes a `Lint.Configuration` from the file-scope `manifest`
// declaration (mirroring `Package.swift`'s `let package = ...` shape),
// runs `Lint.Run.run(paths:configuration:)` against argv, and emits
// findings via the institute reporter.
//
// swift-linter (the central CLI) detects this Lint/Package.swift at the
// consumer root and delegates the lint run by spawning
// `swift run --package-path <consumerRoot>/Lint Lint <args>`. Single-
// file `Lint.swift` consumers continue to use the existing
// chain-resolution path; the dispatch is additive.

import PackageDescription

let package = Package(
    name: "Lint",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .executable(
            name: "Lint",
            targets: ["Lint"]
        ),
        .library(
            name: "Linter Rule Tagged Domain Audit",
            targets: ["Linter Rule Tagged Domain Audit"]
        ),
    ],
    dependencies: [
        // Engine — provides Lint.run() and the engine types.
        .package(url: "https://github.com/swift-foundations/swift-linter.git", branch: "main"),
        // Primitives-tier rules bundle — publishes Lint.Rule.Bundle.primitives,
        // which transitively pulls institute + universal rules. ONE direct
        // dep; SwiftPM walks the chain for the rest.
        .package(url: "https://github.com/swift-primitives/swift-primitives-linter-rules.git", branch: "main"),
        // swift-linter-rules path dep is needed only because the custom
        // rule's test target depends on Linter Rules Test Support; the
        // executable itself never references swift-linter-rules products
        // directly.
        .package(url: "https://github.com/swift-foundations/swift-linter-rules.git", branch: "main"),
        // L1 primitives surface used by the custom rule (Lint.Rule witness types).
        .package(url: "https://github.com/swift-primitives/swift-linter-primitives.git", branch: "main"),
        // Domain dep — the consumer IS the domain; the custom rule imports it.
        .package(path: ".."),
        // SwiftSyntax for the custom rule's AST visitor.
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "602.0.0"..<"603.0.0"),
    ],
    targets: [
        .target(
            name: "Linter Rule Tagged Domain Audit",
            dependencies: [
                .product(name: "Linter Primitives", package: "swift-linter-primitives"),
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ]
        ),
        .executableTarget(
            name: "Lint",
            dependencies: [
                "Linter Rule Tagged Domain Audit",
                .product(name: "Linter", package: "swift-linter"),
                .product(name: "Linter Primitives Rules", package: "swift-primitives-linter-rules"),
            ]
        ),
        .testTarget(
            name: "Linter Rule Tagged Domain Audit Tests",
            dependencies: [
                "Linter Rule Tagged Domain Audit",
                .product(name: "Linter Primitives", package: "swift-linter-primitives"),
                .product(name: "Linter Rules Test Support", package: "swift-linter-rules"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    ]

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem
}
