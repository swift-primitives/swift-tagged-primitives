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
        // Path-based deps. URL-based switch deferred post-cohort because
        // the new repos (swift-manifest-primitives, swift-linter-rules)
        // ship PRIVATE; URL-based SwiftPM resolution would fail at CI
        // runtime without auth tokens. Path-based works for local
        // development against the developer's clone-mirror layout
        // (~/Developer/<org>/<pkg>); when CI auth is sorted (or selective
        // visibility flips happen) a small follow-up dispatch switches
        // to URL-based form.

        // Engine + reporter umbrella. Post-Phase-B.1 swift-linter no longer
        // ships rule packs; the consumer declares them directly below.
        .package(path: "../../../swift-foundations/swift-linter"),
        // Institute-canonical rule packs — the consumer wires the subset
        // referenced by the file-scope manifest's enabledRuleIDs.
        .package(path: "../../../swift-foundations/swift-linter-rules"),
        // L1 primitives surface used by the custom rule's Lint.Rule.Protocol conformance.
        .package(path: "../../swift-linter-primitives"),
        // Domain dep — the consumer (swift-tagged-primitives) IS the domain;
        // imported by the custom rule to validate the PoC's load-bearing
        // domain-aware-import mechanism.
        .package(path: ".."),
        // SwiftSyntax for the rule's AST visitor.
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
                .product(name: "Linter Reporter Text", package: "swift-linter"),
                // Tier 2 institute baselines (R1–R5).
                .product(name: "Linter Rule Unchecked", package: "swift-linter-rules"),
                .product(name: "Linter Rule Cardinal", package: "swift-linter-rules"),
                .product(name: "Linter Rule RawValue", package: "swift-linter-rules"),
                // Carry-forward institute-canonical rule (Phase 2).
                .product(name: "Linter Rule ResultBuilder", package: "swift-linter-rules"),
                // Wave-1 AI-harness rules (Phase 4).
                .product(name: "Linter Rule Try Optional", package: "swift-linter-rules"),
                .product(name: "Linter Rule Untyped Throws", package: "swift-linter-rules"),
                .product(name: "Linter Rule Existential Throws", package: "swift-linter-rules"),
                .product(name: "Linter Rule Var Named Impl", package: "swift-linter-rules"),
                .product(name: "Linter Rule Option Named Flags", package: "swift-linter-rules"),
                .product(name: "Linter Rule Compound Identifier", package: "swift-linter-rules"),
                .product(name: "Linter Rule Tag Suffix", package: "swift-linter-rules"),
            ]
        ),
        .testTarget(
            name: "Linter Rule Tagged Domain Audit Tests",
            dependencies: [
                "Linter Rule Tagged Domain Audit",
                .product(name: "Linter Primitives", package: "swift-linter-primitives"),
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
