// Tagged+Carrier.Protocol.swift
// Tagged conforms to Carrier.`Protocol` (a.k.a. Carrying), with the
// witness `Underlying` cascading through the immediate generic-param
// `Underlying` to the bottom of the chain.
//
// The witness signatures use `Self.Underlying` qualification because
// the protocol's associated-type witness and Tagged's generic
// parameter share the name `Underlying`. Inside this extension's
// scope, `Self.Underlying` resolves to the typealias witness
// (`Underlying.Underlying`, the cascade end), and unqualified
// `Underlying` resolves to the generic parameter (the immediate
// wrapped type). The init body uses both: `Self.Underlying` for the
// parameter type, `Underlying` for the constructor of the immediate
// wrapper.

public import Carrier_Primitives

// MARK: - Carrier.`Protocol` Conformance

/// Tagged is a Carrier whenever its `Underlying` is.
///
/// The conformance cascades: `Tagged<Tag, Underlying>.Underlying ==
/// Underlying.Underlying`. For a single-level wrapper like
/// `Tagged<User, Cardinal>` (where `Cardinal: Carrier.\`Protocol\``
/// with `Underlying == Cardinal`), this gives
/// `Tagged<User, Cardinal>.Underlying == Cardinal`. For nested wrappers
/// like `Tagged<X, Tagged<Y, Cardinal>>`, the cascade resolves
/// `Underlying` all the way down to the innermost trivial-self-carrier.
///
/// This is the move that lets `some Carrier.\`Protocol\`<Cardinal>`
/// accept bare `Cardinal`, `Tagged<User, Cardinal>`, and any
/// further-nested Tagged variant uniformly.
///
/// The phantom `Tag` becomes the Carrier's `Domain` discriminator,
/// preserving the "phantom-typed wrappers stay distinct" property
/// at the protocol level.
extension Tagged: Carrier.`Protocol`
where Tag: ~Copyable & ~Escapable, Underlying: Carrier.`Protocol` & ~Copyable & ~Escapable {
    /// The phantom `Tag` IS the Carrier's `Domain`.
    public typealias Domain = Tag

    /// `Underlying` cascades through the generic-param's own Carrier
    /// conformance. The LHS is the protocol witness; the RHS first
    /// `Underlying` is Tagged's generic parameter; this resolves to the
    /// cascade-end type for both trivial-self and nested cases.
    public typealias Underlying = Underlying.Underlying

    /// Borrowing access to the cascade-end underlying value, threaded
    /// through the immediate generic-param's `.underlying`. The
    /// `_read` coroutine yields by borrow, supporting both `Copyable`
    /// and `~Copyable` Underlying.
    ///
    /// Note: the property type is `Self.Underlying` (the typealias
    /// witness, which is the cascade-end type), not the unqualified
    /// `Underlying` (which would resolve to the generic parameter).
    /// This qualification is required because the names collide.
    ///
    /// The `@_lifetime(borrow self)` annotation lives on the protocol
    /// declaration; conformers do not repeat it.
    public var underlying: Self.Underlying {
        @_lifetime(borrow self)
        _read { yield _storage.underlying }
    }

    /// Constructs a tagged carrier from a cascade-end underlying value
    /// by reconstructing the intermediate immediate-level value via its
    /// own Carrier init, then wrapping. The chain transfers ownership
    /// end-to-end: cascade-end → intermediate → Tagged.
    ///
    /// In the body, `Underlying(underlying)` uses the GENERIC-PARAMETER
    /// `Underlying` (the immediate wrapped type) to construct that
    /// intermediate value from the cascade-end value. The result is
    /// then handed to `_unchecked:` to wrap into Tagged.
    ///
    /// The `@_lifetime(copy underlying)` annotation lives on the
    /// protocol declaration; conformers do not repeat it.
    @_lifetime(copy underlying)
    public init(_ underlying: consuming Self.Underlying) {
        self.init(_unchecked: Underlying(underlying))
    }
}
