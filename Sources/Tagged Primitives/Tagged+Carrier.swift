// Tagged+Carrier.swift
// Tagged conforms to Carrier, with Underlying cascading through RawValue.

public import Carrier_Primitives

// MARK: - Carrier Conformance

/// Tagged is a Carrier whenever its RawValue is.
///
/// The conformance cascades: `Tagged<Tag, RawValue>.Underlying ==
/// RawValue.Underlying`. For a single-level wrapper like
/// `Tagged<User, Cardinal>` (where `Cardinal: Carrier` with
/// `Underlying == Cardinal`), this gives
/// `Tagged<User, Cardinal>.Underlying == Cardinal`. For nested wrappers
/// like `Tagged<X, Tagged<Y, Cardinal>>`, the cascade resolves
/// `Underlying` all the way down to the innermost trivial-self-carrier.
///
/// This is the move that lets `some Carrier<Cardinal>` accept bare
/// `Cardinal`, `Tagged<User, Cardinal>`, and any further-nested
/// Tagged variant uniformly — subsuming the per-type
/// `Cardinal.\`Protocol\`` cascade with a single parametric extension.
///
/// The phantom `Tag` becomes the Carrier's `Domain` discriminator,
/// preserving the "phantom-typed wrappers stay distinct" property
/// at the Carrier-protocol level.
extension Tagged: Carrier
where Tag: ~Copyable & ~Escapable, RawValue: Carrier {
    /// The phantom `Tag` IS the Carrier's `Domain`.
    public typealias Domain = Tag

    /// `Underlying` cascades through `RawValue`'s Carrier conformance.
    public typealias Underlying = RawValue.Underlying

    /// Borrowing access to the underlying value, threaded through
    /// `RawValue.underlying`. The `_read` coroutine yields by borrow,
    /// supporting both `Copyable` and `~Copyable` Underlying.
    ///
    /// The `@_lifetime(borrow self)` annotation lives on the protocol
    /// declaration; conformers do not repeat it.
    public var underlying: Underlying {
        _read { yield rawValue.underlying }
    }

    /// Constructs a tagged carrier from an underlying value by
    /// reconstructing the intermediate `RawValue` via its own Carrier
    /// init, then wrapping. The chain transfers ownership end-to-end:
    /// `Underlying → RawValue → Tagged`.
    ///
    /// The `@_lifetime(copy underlying)` annotation lives on the protocol
    /// declaration; conformers do not repeat it. Verified against
    /// `swift-carrier-primitives/Sources/Carrier Primitives/Carrier.swift:39, 48`
    /// — the protocol carries the annotation, so this conformer correctly
    /// omits it. Do not add a duplicate here.
    public init(_ underlying: consuming Underlying) {
        self.init(__unchecked: (), RawValue(underlying))
    }
}
