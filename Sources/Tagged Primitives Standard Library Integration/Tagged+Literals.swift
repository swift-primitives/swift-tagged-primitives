// Tagged+Literals.swift
// Opt-in `ExpressibleBy*Literal` conformances for `Tagged<Tag, RawValue>`
// when `RawValue` conforms. Each conformance forwards the literal init
// to `RawValue`'s corresponding init, then constructs the Tagged value
// via `init(__unchecked:_:)`.
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
where Tag: ~Copyable, RawValue: ExpressibleByIntegerLiteral {
    /// Constructs a tagged value from an integer literal by forwarding
    /// to `RawValue(integerLiteral:)`. Marked `@_disfavoredOverload` to
    /// keep domain-specific inits ranked higher in resolution.
    @_disfavoredOverload
    public init(integerLiteral value: RawValue.IntegerLiteralType) {
        self = .init(__unchecked: (), RawValue(integerLiteral: value))
    }
}

extension Tagged: ExpressibleByFloatLiteral
where Tag: ~Copyable, RawValue: ExpressibleByFloatLiteral {
    /// Constructs a tagged value from a floating-point literal by
    /// forwarding to `RawValue(floatLiteral:)`.
    @_disfavoredOverload
    public init(floatLiteral value: RawValue.FloatLiteralType) {
        self.init(__unchecked: (), RawValue(floatLiteral: value))
    }
}

extension Tagged: ExpressibleByUnicodeScalarLiteral
where Tag: ~Copyable, RawValue: ExpressibleByUnicodeScalarLiteral {
    /// Constructs a tagged value from a Unicode-scalar literal by
    /// forwarding to `RawValue(unicodeScalarLiteral:)`.
    @_disfavoredOverload
    public init(unicodeScalarLiteral value: RawValue.UnicodeScalarLiteralType) {
        self.init(__unchecked: (), RawValue(unicodeScalarLiteral: value))
    }
}

extension Tagged: ExpressibleByExtendedGraphemeClusterLiteral
where Tag: ~Copyable, RawValue: ExpressibleByExtendedGraphemeClusterLiteral {
    /// Constructs a tagged value from an extended-grapheme-cluster
    /// literal by forwarding to `RawValue(extendedGraphemeClusterLiteral:)`.
    @_disfavoredOverload
    public init(extendedGraphemeClusterLiteral value: RawValue.ExtendedGraphemeClusterLiteralType) {
        self.init(__unchecked: (), RawValue(extendedGraphemeClusterLiteral: value))
    }
}

extension Tagged: ExpressibleByStringLiteral
where Tag: ~Copyable, RawValue: ExpressibleByStringLiteral {
    /// Constructs a tagged value from a string literal by forwarding to
    /// `RawValue(stringLiteral:)`. Note: in SLI scope,
    /// `Tagged<Tag, T>("string")` (parenthesized init form) is ambiguous
    /// because of the interaction with `LosslessStringConvertible` —
    /// disambiguate via `Tagged<Tag, T>(String("…"))`.
    @_disfavoredOverload
    public init(stringLiteral value: RawValue.StringLiteralType) {
        self.init(__unchecked: (), RawValue(stringLiteral: value))
    }
}

extension Tagged: ExpressibleByBooleanLiteral
where Tag: ~Copyable, RawValue: ExpressibleByBooleanLiteral {
    /// Constructs a tagged value from a Boolean literal by forwarding
    /// to `RawValue(booleanLiteral:)`.
    @_disfavoredOverload
    public init(booleanLiteral value: RawValue.BooleanLiteralType) {
        self.init(__unchecked: (), RawValue(booleanLiteral: value))
    }
}

extension Tagged: ExpressibleByStringInterpolation
where Tag: ~Copyable, RawValue: ExpressibleByStringInterpolation {
    /// Constructs a tagged value from a string interpolation by
    /// forwarding to `RawValue(stringInterpolation:)`.
    @_disfavoredOverload
    public init(stringInterpolation: RawValue.StringInterpolation) {
        self.init(__unchecked: (), RawValue(stringInterpolation: stringInterpolation))
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
// only Array-family RawValues without `Set`, `Dictionary`, or other
// non-RRC types. Per user direction 2026-04-30, the carve-out covers
// the asymmetry uniformly.
//
// The bitcast is strictly a function-type reinterpretation: it converts
// `(Element...) -> RawValue` to `([Element]) -> RawValue`. Both function
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
where Tag: ~Copyable, RawValue: ExpressibleByArrayLiteral {
    /// Constructs a tagged value from an array literal by reinterpreting
    /// `RawValue`'s variadic `init(arrayLiteral:)` as an array-typed
    /// init via `unsafeBitCast`. **`[MEM-SAFE-001]` carve-out site #1
    /// of 2** — see the file's MARK block for provenance and ABI
    /// rationale; see `Research/principled-absence-array-dict-literal.md`
    /// v1.2.0 for the carve-out's bounded scope.
    @_disfavoredOverload
    public init(arrayLiteral elements: RawValue.ArrayLiteralElement...) {
        let f = unsafe unsafeBitCast(
            RawValue.init(arrayLiteral:) as (RawValue.ArrayLiteralElement...) -> RawValue,
            to: (([RawValue.ArrayLiteralElement]) -> RawValue).self
        )
        self.init(__unchecked: (), f(elements))
    }
}

extension Tagged: ExpressibleByDictionaryLiteral
where Tag: ~Copyable, RawValue: ExpressibleByDictionaryLiteral {
    /// Constructs a tagged value from a dictionary literal by
    /// reinterpreting `RawValue`'s variadic `init(dictionaryLiteral:)`
    /// as a tuple-array-typed init via `unsafeBitCast`. **`[MEM-SAFE-001]`
    /// carve-out site #2 of 2** — see the file's MARK block for
    /// provenance and ABI rationale.
    @_disfavoredOverload
    public init(dictionaryLiteral elements: (RawValue.Key, RawValue.Value)...) {
        let f = unsafe unsafeBitCast(
            RawValue.init(dictionaryLiteral:) as ((RawValue.Key, RawValue.Value)...) -> RawValue,
            to: (([(RawValue.Key, RawValue.Value)]) -> RawValue).self
        )
        self.init(__unchecked: (), f(elements))
    }
}
