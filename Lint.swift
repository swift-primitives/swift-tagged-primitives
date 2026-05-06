// parent: https://raw.githubusercontent.com/swift-primitives/.github/main/Lint.swift
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
// `Package.swift`'s manifest pattern. It declares a file-scope
// `let manifest: Lint.Manifest` value; the linter detects the file at
// the consumer package root, compiles + runs it via swift-manifest,
// captures the JSON-serialized manifest, and constructs a runtime
// Lint.Configuration from the manifest's enabled rule IDs.
//
// Phase 2 Stream B v2 — Manifest.load path (compile + run + capture):
// activates all five built-in rules (R1–R5). The effective rule set
// matches the v1-default Lint.Rule.builtIn-everything-enabled
// configuration; this file exists to validate the v2 evaluation
// surface end-to-end against the swift-tagged-primitives source tree.
//
// Inherits from Tier 2 (swift-primitives/.github/Lint.swift) via the
// `// parent:` directive at the top of this file. Tier 2 itself
// inherits from Tier 1 (swift-institute/.github/Lint.swift). The
// consumer's enabledRuleIDs list overlaps Tier 2 fully — the effective
// set is unchanged whether the parent chain resolves successfully or
// the curl fetch falls back to consumer-only configuration. This
// matches the pre-migration baseline 27 R5 hits exactly.
//
// References:
//
// - swift-institute/Research/swiftsyntax-based-custom-linter-investigation.md
// - HANDOFF-file-based-canonical-migration-phase-2.md

import Linter

let manifest = Lint.Manifest(
    enabledRuleIDs: [
        "unchecked_call_site",                 // R5
        "cardinal_count_minus_one",            // R1
        "cardinal_zero_one_constructor",       // R2
        "chained_rawvalue_access",             // R3
        "bitpattern_rawvalue_chain"            // R4
    ]
)
