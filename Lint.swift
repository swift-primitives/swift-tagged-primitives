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

// `Lint.swift` is the typed-Swift-DSL configuration file for the
// SwiftSyntax-based linter (swift-foundations/swift-linter), mirroring
// `Package.swift`'s manifest pattern. It declares a public
// `let configuration: Lint.Configuration` value at file scope; the linter
// detects the file at the consumer package root and applies the
// configuration to its run.
//
// Phase 1.5 Item 5 v1 — proof-of-concept for swift-tagged-primitives:
// inherits SwiftPrimitivesLintCanonical.tier2 (which activates R5 —
// `unchecked_call_site` — at warning severity); no per-package overrides,
// no excluded paths, no custom rules. The effective rule set is
// equivalent to the v1-default Lint.Rule.builtIn-everything-enabled
// configuration the linter already applies when no Lint.swift is present;
// this file exists to validate the architecture end-to-end and to be
// the canonical example of the typed-DSL shape for other primitives
// packages to copy.
//
// References:
//
// - swift-institute/Research/swiftsyntax-based-custom-linter-investigation.md
// - HANDOFF-swiftsyntax-linter-phase-1-5.md (§"Phase 1.5 Expansion (2026-05-06):
//   Item 5 — Lint.swift DSL + drop YAML entirely")

import Linter_Primitives
import Swift_Primitives_Lint_Canonical

let configuration = Lint.Configuration(
    inheriting: SwiftPrimitivesLintCanonical.tier2,
    rules: {
        // No per-package overrides. swift-tagged-primitives takes the
        // Tier 2 canonical defaults directly. Future overrides land here:
        //
        //   .override(SwiftPrimitivesLintCanonical.UncheckedCallSite.self, severity: .error)
        //   .disable(SwiftPrimitivesLintCanonical.UncheckedCallSite.self)
    }
)
