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
// Under the nested-package mechanism, swift-linter (CLI) detects this
// consumer's `Lint/Package.swift` and delegates the lint run by spawning
// `swift run --package-path <consumerRoot>/Lint Lint <args>`. The
// nested-package binary IS the linter for this consumer — it links
// engine + rule packs + the PoC's domain-aware custom rule, builds a
// `Lint.Configuration` from the typed-metatype DSL below, runs
// `Lint.Run.run`, and emits findings via the institute reporter.
//
// Inherits from Tier 2 (`swift-primitives/.github/Lint.swift`) via the
// `// parent:` directive at the top of this file. Tier 2 itself
// inherits from Tier 1 (`swift-institute/.github/Lint.swift`). The
// chain-resolution machinery still lives in Manifest Resolver; the
// dispatch path leaves chain-walking to a future Phase B sub-phase.
//
// `Lint.Manifest` is the JSON wire-format boundary type for the
// single-file `Lint.swift` subprocess path (where rule references must
// cross the swift-manifest subprocess gap as bare strings). The
// nested-package binary has no JSON crossing — metatypes flow directly
// — so the consumer surface here is the typed `Lint.Configuration`
// alone, per `swift-institute/Research/2026-05-07-swift-linter-consumer-syntax.md`
// §Outcome Q1b.

internal import File_System
internal import Linter
internal import Linter_Reporter_Text
internal import Linter_Rule_Cardinal
internal import Linter_Rule_Naming
internal import Linter_Rule_RawValue
internal import Linter_Rule_ResultBuilder
internal import Linter_Rule_Tagged_Domain_Audit
internal import Linter_Rule_Throws
internal import Linter_Rule_Try
internal import Linter_Rule_Unchecked
internal import Terminal_Primitives

// Fully-qualified `Lint.Rule.Configuration.enable(...)` is required at the
// top-level element position of the `Array<Lint.Rule.Configuration>.Builder`
// result-builder: the builder declares four `buildExpression` overloads
// (Element / [Element] / Sequence / Element?) so leading-dot `.enable(...)`
// is ambiguous in the unconstrained position. Inside `if` / `for` bodies
// the contextual type is narrowed to `Element` and the leading-dot form
// works there. The fully-qualified form is uniformly correct.
let configuration = Lint.Configuration {
    // Tier 2 R5 — call-site `__unchecked:` argument label.
    Lint.Rule.Configuration.enable(Lint.Rule.Unchecked.self)
    // Tier 2 R1 — `count - 1` and algebraic-flip equivalents.
    Lint.Rule.Configuration.enable(Lint.Rule.Cardinal.Count.self)
    // Tier 2 R2 — `Cardinal(0)` / `Cardinal(1)` constructors.
    Lint.Rule.Configuration.enable(Lint.Rule.Cardinal.Constructor.self)
    // Tier 2 R3 — chained `.rawValue.X` member access.
    Lint.Rule.Configuration.enable(Lint.Rule.RawValue.Chain.self)
    // Tier 2 R4 — `X(bitPattern: …rawValue)` integration anti-pattern.
    Lint.Rule.Configuration.enable(Lint.Rule.RawValue.BitPattern.self)
    // Carry-forward Phase-2 rule — `for` inside `@resultBuilder` body.
    Lint.Rule.Configuration.enable(Lint.Rule.ResultBuilder.ForLoop.self)
    // Wave-1 AI-harness rules (Phase 4).
    Lint.Rule.Configuration.enable(Lint.Rule.Try.self)
    Lint.Rule.Configuration.enable(Lint.Rule.Throws.Untyped.self)
    Lint.Rule.Configuration.enable(Lint.Rule.Throws.Existential.self)
    Lint.Rule.Configuration.enable(Lint.Rule.Naming.Impl.self)
    Lint.Rule.Configuration.enable(Lint.Rule.Naming.Options.self)
    Lint.Rule.Configuration.enable(Lint.Rule.Naming.Compound.self)
    Lint.Rule.Configuration.enable(Lint.Rule.Naming.Tag.self)
    // PoC custom rule — Tagged-domain-aware, outside the institute
    // canonical packs by design.
    Lint.Rule.Configuration.enable(Lint.Rule.TaggedDomainAudit.self)
}

let arguments = Swift.CommandLine.arguments
let pathStrings: [Swift.String] = arguments.count >= 2
    ? [Swift.String](arguments.dropFirst())
    : ["."]

do {
    let consumerPaths: [File.Path] = try pathStrings.map { try File.Path($0) }
    let findings = try Lint.Run.run(paths: consumerPaths, configuration: configuration)
    Lint.Reporter.Text.emit(findings: findings, to: Terminal.Stream.stdout.write)
} catch {
    print("[Lint] error: \(error)")
}
