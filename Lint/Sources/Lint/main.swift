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
// Consumes `Lint.Rule.Bundle.primitives` (the primitives-tier bundle,
// which transitively includes institute + universal rules) plus the
// PoC's Tagged-domain-aware custom rule.

internal import Linter
internal import Linter_Primitives_Rules
internal import Linter_Rule_Tagged_Domain_Audit

Lint.run(
    configuration: Lint.Configuration {
        Lint.Rule.Bundle.primitives
        Lint.Rule.Configuration.enable(.`tagged unchecked with typed alternative`)
    }
)
