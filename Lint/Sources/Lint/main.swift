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

// Lint executable — the linter binary for swift-tagged-primitives.
//
// PoC of the Lint/ nested-package mechanism (architecture cohort Phase A).
// Under Option 1 (resolver + swift-linter CLI dispatch full linting):
// swift-linter (CLI) detects this consumer's `Lint/Package.swift` and
// delegates the lint run by spawning `swift run --package-path
// <consumerRoot>/Lint Lint <args>`. This executable composes a
// Configuration from the file-scope `manifest` declaration plus the
// PoC's domain-aware custom rule, runs `Lint.Run.run`, and emits
// findings via the institute reporter.
//
// Inherits from Tier 2 (`swift-primitives/.github/Lint.swift`) via the
// `// parent:` directive at the top of this file. Tier 2 itself
// inherits from Tier 1 (`swift-institute/.github/Lint.swift`).
// The chain-resolution machinery still lives in Manifest Resolver;
// the dispatch path leaves chain-walking to a future Phase B sub-phase
// — for the PoC we exercise the consumer-only manifest that previously
// worked under the single-file path (R1–R5), augmented by the custom
// rule's ID.

internal import Linter
internal import Linter_Reporter_Text
internal import Linter_Rule_Cardinal
internal import Linter_Rule_Compound_Identifier
internal import Linter_Rule_Existential_Throws
internal import Linter_Rule_Option_Named_Flags
internal import Linter_Rule_RawValue
internal import Linter_Rule_ResultBuilder
internal import Linter_Rule_Tag_Suffix
internal import Linter_Rule_Tagged_Domain_Audit
internal import Linter_Rule_Try_Optional
internal import Linter_Rule_Unchecked
internal import Linter_Rule_Untyped_Throws
internal import Linter_Rule_Var_Named_Impl
internal import Terminal_Primitives

/// File-scope manifest declaration mirroring the single-file Lint.swift
/// shape (analogous to Package.swift's `let package = Package(...)`).
/// The `enabledRuleIDs` list drives runtime activation; rule TYPES are
/// enumerated explicitly below since post-Phase-B.1 the engine no
/// longer ships a built-in catalog (`Lint.Rule.builtIn` was removed).
let manifest = Lint.Manifest(
    enabledRuleIDs: [
        // Tier 2 R5 — call-site `__unchecked:` argument label.
        "unchecked_call_site",
        // Tier 2 R1 — `count - 1` and algebraic-flip equivalents.
        "cardinal_count_minus_one",
        // Tier 2 R2 — `Cardinal(0)` / `Cardinal(1)` constructors.
        "cardinal_zero_one_constructor",
        // Tier 2 R3 — chained `.rawValue.X` member access.
        "chained_rawvalue_access",
        // Tier 2 R4 — `X(bitPattern: …rawValue)` integration anti-pattern.
        "bitpattern_rawvalue_chain",
        // Carry-forward Phase-2 rule — `for` inside `@resultBuilder` body.
        "result_builder_for_loop",
        // Wave-1 AI-harness rules (Phase 4).
        "try_optional",
        "untyped_throws",
        "existential_throws",
        "var_named_impl",
        "option_named_flags",
        "compound_identifier",
        "tag_suffix",
        // PoC custom rule — Tagged-`_unchecked:` domain-aware detection.
        "tagged_unchecked_with_typed_alternative",
    ]
)

// argv[1...] = consumer source paths; default to "." when invoked with
// no arguments.
let arguments = Swift.CommandLine.arguments
let consumerPaths: [Swift.String]
if arguments.count >= 2 {
    consumerPaths = [Swift.String](arguments.dropFirst())
} else {
    consumerPaths = ["."]
}

let enabled = Swift.Set(manifest.enabledRuleIDs)

let configuration = Lint.Configuration(
    rules: {
        // Institute-canonical rule packs (R1–R5) — type-enumerated by
        // the consumer; activation gated on the manifest's enabledRuleIDs.
        if enabled.contains(Lint.Rule.Unchecked.id) {
            Lint.Rule.Configuration.enable(Lint.Rule.Unchecked.self)
        }
        if enabled.contains(Lint.Rule.Cardinal.Count.id) {
            Lint.Rule.Configuration.enable(Lint.Rule.Cardinal.Count.self)
        }
        if enabled.contains(Lint.Rule.Cardinal.Constructor.id) {
            Lint.Rule.Configuration.enable(Lint.Rule.Cardinal.Constructor.self)
        }
        if enabled.contains(Lint.Rule.RawValue.Chain.id) {
            Lint.Rule.Configuration.enable(Lint.Rule.RawValue.Chain.self)
        }
        if enabled.contains(Lint.Rule.RawValue.BitPattern.id) {
            Lint.Rule.Configuration.enable(Lint.Rule.RawValue.BitPattern.self)
        }
        // Carry-forward Phase-2 rule (PoC Phase A onboarded R1–R5 + R0
        // implicitly via Lint.Rule.builtIn; Phase B.4 explicitly wires
        // the remaining institute-canonical pack).
        if enabled.contains(Lint.Rule.ResultBuilderForLoop.id) {
            Lint.Rule.Configuration.enable(Lint.Rule.ResultBuilderForLoop.self)
        }
        // Wave-1 AI-harness rules (Phase 4).
        if enabled.contains(Lint.Rule.TryOptional.id) {
            Lint.Rule.Configuration.enable(Lint.Rule.TryOptional.self)
        }
        if enabled.contains(Lint.Rule.UntypedThrows.id) {
            Lint.Rule.Configuration.enable(Lint.Rule.UntypedThrows.self)
        }
        if enabled.contains(Lint.Rule.ExistentialThrows.id) {
            Lint.Rule.Configuration.enable(Lint.Rule.ExistentialThrows.self)
        }
        if enabled.contains(Lint.Rule.VarNamedImpl.id) {
            Lint.Rule.Configuration.enable(Lint.Rule.VarNamedImpl.self)
        }
        if enabled.contains(Lint.Rule.OptionNamedFlags.id) {
            Lint.Rule.Configuration.enable(Lint.Rule.OptionNamedFlags.self)
        }
        if enabled.contains(Lint.Rule.CompoundIdentifier.id) {
            Lint.Rule.Configuration.enable(Lint.Rule.CompoundIdentifier.self)
        }
        if enabled.contains(Lint.Rule.TagSuffix.id) {
            Lint.Rule.Configuration.enable(Lint.Rule.TagSuffix.self)
        }
        // PoC custom rule — Tagged-domain-aware, outside the institute
        // canonical packs by design (see `[REFINED-CONSTRAINT-1]` in the
        // PoC verification record).
        if enabled.contains(Lint.Rule.TaggedDomainAudit.id) {
            Lint.Rule.Configuration.enable(Lint.Rule.TaggedDomainAudit.self)
        }
    }
)

do {
    let findings = try Lint.Run.run(paths: consumerPaths, configuration: configuration)
    Lint.Reporter.emit(findings: findings, to: Terminal.Stream.stdout.write)
} catch {
    print("[Lint] error: \(error)")
}
