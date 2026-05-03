// Tagged+Carrier.Protocol.swift
//
// Tagged is unconditionally a Carrier of its IMMEDIATE Underlying.
// No cascade, no constraint on what Underlying is.
//
// Earlier revisions encoded a cascade — `Tagged<X, Tagged<Y, Int>>.Underlying
// resolved to Int (the bottom-most type) by requiring `Underlying: Carrier.\`Protocol\``
// and recursing through `Underlying.Underlying`. That design forced four
// real costs onto every consumer:
//
//   1. Tagged was not a Carrier when Underlying wasn't (e.g.,
//      `Tagged<Tag, Ownership.Inout<Base>>` couldn't get the conformance
//      because `Ownership.Inout` is a scoped projection, not an owned value
//      that can satisfy Carrier's consuming init — Property.View was blocked).
//   2. Name-shadowing complexity: `Self.Underlying` (cascade-end) vs
//      `Underlying` (generic param) collided; conformers had to qualify.
//   3. Brittle transitive dependency: Tagged's Carrier-ness depended on
//      Underlying's Carrier-ness, all the way down.
//   4. A leaky abstraction: nested Tagged exposed only the bottom-most type,
//      hiding intermediate structure that consumers might need.
//
// The immediate-Underlying form here unconditional, has no shadowing, no
// transitive dependency, and is honest about nested structure. The
// payoff lost — uniform `some Carrier.\`Protocol\`<Cardinal>` over arbitrary
// nesting depth — was rare-to-nonexistent in practice; consumers that
// genuinely need it write the recursion at the API site.

public import Carrier_Primitives

// MARK: - Carrier.`Protocol` Conformance (unconditional, immediate)

/// Tagged is always a Carrier of its immediate `Underlying`, regardless of
/// what `Underlying` is.
///
/// The phantom `Tag` becomes the Carrier's `Domain` discriminator,
/// preserving the "phantom-typed wrappers stay distinct" property at the
/// protocol level.
///
/// `Tagged<Tag, U>.Underlying == U`. For nested `Tagged<X, Tagged<Y, Int>>`,
/// `.Underlying == Tagged<Y, Int>` (the immediate wrapped type) — to reach
/// `Int`, recurse: `tagged.underlying.underlying`.
extension Tagged: Carrier.`Protocol`
where Tag: ~Copyable & ~Escapable, Underlying: ~Copyable & ~Escapable {
    /// The phantom `Tag` IS the Carrier's `Domain`.
    public typealias Domain = Tag

    /// `Underlying` is the immediate generic parameter — no cascade.
    public typealias Underlying = Underlying

    /// Borrowing access to the wrapped value via a `_read` coroutine.
    /// Yields directly out of `_storage`; supports both `Copyable` and
    /// `~Copyable` Underlying.
    ///
    /// The `@_lifetime(borrow self)` annotation lives on the protocol
    /// declaration; conformers do not repeat it.
    public var underlying: Underlying {
        @_lifetime(borrow self)
        _read { yield _storage }
    }

    /// Constructs a tagged carrier by directly storing the consumed
    /// underlying value. No transitive Carrier construction — the
    /// generic-parameter `Underlying` is accepted as-is.
    ///
    /// The `@_lifetime(copy underlying)` annotation lives on the protocol
    /// declaration; conformers do not repeat it.
    @_lifetime(copy underlying)
    public init(_ underlying: consuming Underlying) {
        self.init(_unchecked: underlying)
    }
}
