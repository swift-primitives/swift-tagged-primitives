// Tagged Primitives Test Support.swift
//
// Test-support fixtures for `swift-tagged-primitives`. As of 2026-04-30,
// the `ExpressibleBy*Literal` conformances on `Tagged` moved from this
// target to `Tagged Primitives Standard Library Integration` per the
// `sli-literal-vs-strideable-tradeoff.md` (DECISION) decision.
//
// Test Support continues to provide the same ergonomic surface to test
// code by re-exporting the SLI target via `exports.swift`. Test files
// that previously had `let t: Tagged<Tag, Int> = 42` ergonomics via this
// target retain that ergonomics through the SLI re-export — no source
// changes required at the test-file level.
//
// This file is intentionally sparse; future test-only fixtures (factories,
// arbitrary instances for property-based testing, etc.) belong here.
