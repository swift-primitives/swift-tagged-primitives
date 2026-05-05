// Tagged+Literals.swift
// Opt-in `ExpressibleBy*Literal` conformances for `Tagged<Tag, Underlying>`
// when `Underlying` conforms. Each conformance forwards the literal init
// to `Underlying`'s corresponding init, then constructs the Tagged value
// via `init(_unchecked:)`.
//
// All nine literal conformances are bundled in one file: the seven
// stdlib literal protocols share `@_disfavoredOverload` discipline and
// are imported as a cohesive opt-in family; the two collection-literal
// conformances (`ExpressibleByArrayLiteral`, `ExpressibleByDictionaryLiteral`)
// are bundled here because they ship via the documented `unsafeBitCast`
// carve-out (the file's MARK section below) — keeping the whole literal
// family in one place keeps the `@_disfavoredOverload` discipline +
// carve-out provenance auditable as one unit.
//
// Empirically grounded in:
// - `Research/tagged-literal-conformances.md` (DECISION) — original
//   literal conformance design.
// - `Research/tagged-literal-conformances-fresh-perspective.md`
//   (RECOMMENDATION) — the silent-overload-resolution footgun analysis.
// - `Research/sli-literal-vs-strideable-tradeoff.md` (DECISION
//   2026-04-30) — the policy decision to ship literals in SLI rather
//   than Strideable; documents the residual footgun risk and consumer
//   contracts.
// - `Research/principled-absence-array-dict-literal.md` v1.2.0
//   (DECISION 2026-04-30) — the bitcast carve-out's provenance,
//   bounded scope, and ABI-commitment statement.
//
// See also: 9 sibling per-protocol absence research docs at
// `Research/principled-absence-*.md` (each empirically classifying a
// stdlib protocol's status as HARD blocker / SOFT-shipped-in-SLI /
// SOFT-excluded-by-policy) with paired experiments at
// `Experiments/tagged-no-*/`. This file's conformance set is the
// SOFT-shipped-in-SLI cohort; the absence catalog enumerates everything
// not shipping here and why.
//
// The `@_disfavoredOverload` discipline prevents the literal init from
// out-ranking domain-specific inits in most resolution contexts. The
// known footgun reactivates when `Strideable` is also conformed for
// the same Tagged-aliased type — see the trade-off doc for the residual
// risk. Per-domain wrapper structs (Option C of the literal-conformance
// research) remain the safest pattern when the footgun is unacceptable.

extension Tagged: ExpressibleByIntegerLiteral
where Tag: ~Copyable, Underlying: ExpressibleByIntegerLiteral {
    /// Constructs a tagged value from an integer literal by forwarding to `Underlying(integerLiteral:)`.
    ///
    /// Marked `@_disfavoredOverload` to keep domain-specific inits ranked
    /// higher in resolution.
    @_disfavoredOverload
    public init(integerLiteral value: Underlying.IntegerLiteralType) {
        self = .init(_unchecked: Underlying(integerLiteral: value))
    }
}

extension Tagged: ExpressibleByFloatLiteral
where Tag: ~Copyable, Underlying: ExpressibleByFloatLiteral {
    /// Constructs a tagged value from a floating-point literal by
    /// forwarding to `Underlying(floatLiteral:)`.
    @_disfavoredOverload
    public init(floatLiteral value: Underlying.FloatLiteralType) {
        self.init(_unchecked: Underlying(floatLiteral: value))
    }
}

extension Tagged: ExpressibleByUnicodeScalarLiteral
where Tag: ~Copyable, Underlying: ExpressibleByUnicodeScalarLiteral {
    /// Constructs a tagged value from a Unicode-scalar literal by
    /// forwarding to `Underlying(unicodeScalarLiteral:)`.
    @_disfavoredOverload
    public init(unicodeScalarLiteral value: Underlying.UnicodeScalarLiteralType) {
        self.init(_unchecked: Underlying(unicodeScalarLiteral: value))
    }
}

extension Tagged: ExpressibleByExtendedGraphemeClusterLiteral
where Tag: ~Copyable, Underlying: ExpressibleByExtendedGraphemeClusterLiteral {
    /// Constructs a tagged value from an extended-grapheme-cluster
    /// literal by forwarding to `Underlying(extendedGraphemeClusterLiteral:)`.
    @_disfavoredOverload
    public init(extendedGraphemeClusterLiteral value: Underlying.ExtendedGraphemeClusterLiteralType) {
        self.init(_unchecked: Underlying(extendedGraphemeClusterLiteral: value))
    }
}

extension Tagged: ExpressibleByStringLiteral
where Tag: ~Copyable, Underlying: ExpressibleByStringLiteral {
    /// Constructs a tagged value from a string literal by forwarding to `Underlying(stringLiteral:)`.
    ///
    /// Note: in SLI scope, `Tagged<Tag, T>("string")` (parenthesized init
    /// form) is ambiguous because of the interaction with
    /// `LosslessStringConvertible` — disambiguate via `Tagged<Tag, T>(String("…"))`.
    @_disfavoredOverload
    public init(stringLiteral value: Underlying.StringLiteralType) {
        self.init(_unchecked: Underlying(stringLiteral: value))
    }
}

extension Tagged: ExpressibleByBooleanLiteral
where Tag: ~Copyable, Underlying: ExpressibleByBooleanLiteral {
    /// Constructs a tagged value from a Boolean literal by forwarding
    /// to `Underlying(booleanLiteral:)`.
    @_disfavoredOverload
    public init(booleanLiteral value: Underlying.BooleanLiteralType) {
        self.init(_unchecked: Underlying(booleanLiteral: value))
    }
}

extension Tagged: ExpressibleByStringInterpolation
where Tag: ~Copyable, Underlying: ExpressibleByStringInterpolation {
    /// Constructs a tagged value from a string interpolation by
    /// forwarding to `Underlying(stringInterpolation:)`.
    @_disfavoredOverload
    public init(stringInterpolation: Underlying.StringInterpolation) {
        self.init(_unchecked: Underlying(stringInterpolation: stringInterpolation))
    }
}

// MARK: - Collection-literal conformances (DOCUMENTED [MEM-SAFE-001] CARVE-OUT)
//
// `ExpressibleByArrayLiteral` and `ExpressibleByDictionaryLiteral` use
// the pointfreeco `unsafeBitCast` pattern to bridge the variadic-init
// function reference into an `Array`-init function reference. This is
// the ONLY documented `unsafeBitCast` carve-out from the package's
// otherwise-strict `[MEM-SAFE-001]` opt-in (`.strictMemorySafety()` at
// `Package.swift` line 56).
//
// Why the carve-out: there is no parametric safe-Swift path that covers
// both the Array-shape (Array / ContiguousArray / Data / SetAlgebra-
// shaped Set / custom `ExpressibleByArrayLiteral` types) AND the
// Dictionary-shape (variadic of (Key, Value) tuples). The
// `RangeReplaceableCollection`-constrained safe path (previously
// shipped, 2026-04-30 v1.1.0 of the principled-absence doc) covered
// only Array-family Underlyings without `Set`, `Dictionary`, or other
// non-RRC types. Per user direction 2026-04-30, the carve-out covers
// the asymmetry uniformly.
//
// The bitcast is strictly a function-type reinterpretation: it converts
// `(Element...) -> Underlying` to `([Element]) -> Underlying`. Both function
// types have identical ABI for the variadic-as-array case (Swift's
// variadic is itself an Array under the hood). The conversion is safe
// in practice; it requires `unsafeBitCast` because Swift's type system
// does not surface variadic-vs-array as compatible function types at
// the type level.
//
// Provenance:
// - Research/principled-absence-array-dict-literal.md (DECISION 2026-04-30)
//   v1.2.0 records the carve-out and the per-user authorization.
// - pointfreeco/swift-tagged Tagged.swift — the source pattern this
//   carve-out adopts verbatim (with the conformance constraint added).

extension Tagged: ExpressibleByArrayLiteral
where Tag: ~Copyable, Underlying: ExpressibleByArrayLiteral {
    /// Constructs a tagged value from an array literal.
    ///
    /// Reinterprets `Underlying`'s variadic `init(arrayLiteral:)` as an
    /// array-typed init via `unsafeBitCast`.
    ///
    /// **`[MEM-SAFE-001]` carve-out site #1 of 2** — see the file's MARK
    /// block for provenance and ABI rationale; see
    /// `Research/principled-absence-array-dict-literal.md` v1.2.0 for the
    /// carve-out's bounded scope.
    @_disfavoredOverload
    public init(arrayLiteral elements: Underlying.ArrayLiteralElement...) {
        let f = unsafe unsafeBitCast(
            Underlying.init(arrayLiteral:) as (Underlying.ArrayLiteralElement...) -> Underlying,
            to: (([Underlying.ArrayLiteralElement]) -> Underlying).self
        )
        self.init(_unchecked: f(elements))
    }
}

extension Tagged: ExpressibleByDictionaryLiteral
where Tag: ~Copyable, Underlying: ExpressibleByDictionaryLiteral {
    /// Constructs a tagged value from a dictionary literal.
    ///
    /// Reinterprets `Underlying`'s variadic `init(dictionaryLiteral:)` as a
    /// tuple-array-typed init via `unsafeBitCast`.
    ///
    /// **`[MEM-SAFE-001]` carve-out site #2 of 2** — see the file's MARK
    /// block for provenance and ABI rationale.
    @_disfavoredOverload
    public init(dictionaryLiteral elements: (Underlying.Key, Underlying.Value)...) {
        let f = unsafe unsafeBitCast(
            Underlying.init(dictionaryLiteral:) as ((Underlying.Key, Underlying.Value)...) -> Underlying,
            to: (([(Underlying.Key, Underlying.Value)]) -> Underlying).self
        )
        self.init(_unchecked: f(elements))
    }
}
