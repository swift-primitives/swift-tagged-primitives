// Tagged.swift
// A phantom-type wrapper for type-safe value distinction.
//
// Inspired by swift-tagged by Point-Free (https://github.com/pointfreeco/swift-tagged)

/// A value wrapped with a compile-time phantom type tag.
///
/// `Tagged` provides zero-cost type safety by wrapping an `Underlying`
/// value with a phantom `Tag` parameter that exists only at compile
/// time. The tag is always an existing domain type — the domain itself
/// is the discriminator.
///
/// The tag adds no runtime overhead — only the underlying value is stored.
///
/// ## Example
///
/// ```swift
/// import Tagged_Primitives
/// import Ordinal_Primitives
///
/// typealias Index<Element> = Tagged<Element, Ordinal>
///
/// let graphIndex: Index<Graph> = ...
/// let bitIndex: Index<Bit> = ...
/// // graphIndex == bitIndex  // Error: Graph ≠ Bit
/// ```
///
/// ## Access surface
///
/// Tagged exposes no direct accessor or public init in its own type
/// body. External construction and read access flow through the
/// `Carrier.\`Protocol\`` (a.k.a. `Carrying`) conformance, which is
/// **unconditional** — Tagged is always a Carrier of its immediate
/// `Underlying`, regardless of what `Underlying` is. Callers construct
/// via `Tagged<Tag, U>(value)` and read via `tagged.underlying`
/// (returning the immediate `U`, not a recursively-resolved type).
/// For nested `Tagged<X, Tagged<Y, Int>>`, `.underlying` returns
/// `Tagged<Y, Int>`; consumers that need to reach `Int` recurse.
/// The `_unchecked:` init is also `public` for cross-package consumers
/// whose `Underlying` cannot satisfy Carrier's consuming init (e.g.,
/// `Property.View` wrapping `Tagged<Tag, Ownership.Inout<Base>>`).
@frozen
public struct Tagged<Tag: ~Copyable & ~Escapable, Underlying: ~Copyable & ~Escapable>: ~Copyable, ~Escapable {
    @usableFromInline
    package var _storage: Underlying

    /// Direct construction from an already-validated underlying value.
    ///
    /// The leading underscore + `_unchecked` label signals "bypass any
    /// Carrier-derived validation; you are asserting the value is already
    /// suitable." This is the right path for:
    ///
    /// - SLI conformances and per-domain types within this package
    /// - Cross-package domain wrappers whose `Underlying` cannot itself
    ///   conform to `Carrier.\`Protocol\`` (e.g., `Tagged<Tag, Ownership.Inout<Base>>`
    ///   in `Property.View` — `Inout` is a scoped projection, not an
    ///   owned value, so it cannot satisfy Carrier's consuming init)
    /// - Performance-critical paths where the `Carrier.\`Protocol\``-derived
    ///   `init(_:)` would route through an Underlying init that does
    ///   redundant work
    ///
    /// For the common case where `Underlying: Carrier.\`Protocol\``, prefer
    /// `Tagged<Tag, U>(_ underlying:)` (the Carrier-derived init) so any
    /// domain validation in `U.init(_:)` runs.
    @inlinable
    @_lifetime(copy underlying)
    public init(_unchecked underlying: consuming Underlying) {
        self._storage = underlying
    }
}

// MARK: - `modify`

// `modify` uses an `inout Underlying` closure parameter and is available for
// any combination of Copyable / Escapable on Underlying. The historical
// Swift 6.3 "closure-parameter-lifetime gap for ~Escapable types" was
// revalidated FIXED on Swift 6.3.1 — see
// Experiments/tagged-modify-escapable-revalidation (CONFIRMED, 2026-04-24).
extension Tagged where Tag: ~Copyable & ~Escapable, Underlying: ~Copyable & ~Escapable {
    @inlinable
    package mutating func modify<T>(_ body: (_ underlying: inout Underlying) -> T) -> T {
        body(&self._storage)
    }
}

// MARK: - Conditional Copyable / Escapable

// Tagged admits ~Escapable Underlying. Whether a Tagged instance is Copyable or
// Escapable is derived from the Underlying's independent capabilities.

extension Tagged: Copyable where Tag: ~Copyable & ~Escapable, Underlying: Copyable & ~Escapable {}
extension Tagged: Escapable where Tag: ~Copyable & ~Escapable, Underlying: Escapable & ~Copyable {}

// MARK: - Conditional Conformances (Swift Standard Library)

// These conformances are restricted to Escapable Underlying. They preserve the
// exact pre-generalization behavior: every Underlying that conformed before
// (e.g., Int, String, domain structs) still conforms; ~Escapable Underlyings
// (e.g., Ownership.Inout<Base>) do not participate here.

extension Tagged: Sendable
    where Tag: ~Copyable & ~Escapable, Underlying: ~Copyable & Sendable & Escapable {}

// `BitwiseCopyable` does not currently admit `~Copyable`, so `Escapable` is
// required here on Swift 6.3.1. When `BitwiseCopyable` is widened to admit
// `~Copyable` (the natural next step on the SE-04XX suppressed-protocol
// generality line), revisit this constraint to drop the `& Escapable` half.
extension Tagged: BitwiseCopyable
    where Tag: ~Copyable & ~Escapable, Underlying: BitwiseCopyable & Escapable {}

// SE-0499: Swift.Equatable, Swift.Hashable, Swift.Comparable no longer imply
// Copyable in Swift 6.4. The & ~Copyable suppression lets these conformances
// apply to ~Copyable Underlying types.
#if compiler(>=6.4)
extension Tagged: Equatable
    where Tag: ~Copyable & ~Escapable, Underlying: Equatable & ~Copyable & Escapable {}
extension Tagged: Hashable
    where Tag: ~Copyable & ~Escapable, Underlying: Hashable & ~Copyable & Escapable {}
#else
extension Tagged: Equatable
    where Tag: ~Copyable & ~Escapable, Underlying: Equatable & Escapable {}
extension Tagged: Hashable
    where Tag: ~Copyable & ~Escapable, Underlying: Hashable & Escapable {}
#endif

#if !hasFeature(Embedded)
    extension Tagged: Codable
        where Tag: ~Copyable & ~Escapable, Underlying: Codable & Escapable {}
#endif

#if compiler(>=6.4)
extension Tagged: Comparable
    where Tag: ~Copyable & ~Escapable, Underlying: Comparable & ~Copyable & Escapable {
    @inlinable
    public static func < (lhs: borrowing Tagged, rhs: borrowing Tagged) -> Bool {
        lhs._storage < rhs._storage
    }

    /// Returns the greater of two tagged values.
    ///
    /// - Parameters:
    ///   - a: The first tagged value.
    ///   - b: The second tagged value.
    /// - Returns: The greater of `a` and `b`.
    @inlinable
    public static func max(_ a: consuming Self, _ b: consuming Self) -> Self {
        a._storage >= b._storage ? a : b
    }

    /// Returns the lesser of two tagged values.
    ///
    /// - Parameters:
    ///   - a: The first tagged value.
    ///   - b: The second tagged value.
    /// - Returns: The lesser of `a` and `b`.
    @inlinable
    public static func min(_ a: consuming Self, _ b: consuming Self) -> Self {
        a._storage <= b._storage ? a : b
    }
}
#else
extension Tagged: Comparable
    where Tag: ~Copyable & ~Escapable, Underlying: Comparable & Escapable {
    @inlinable
    public static func < (lhs: Tagged, rhs: Tagged) -> Bool {
        lhs._storage < rhs._storage
    }

    /// Returns the greater of two tagged values.
    ///
    /// Equivalent to `Swift.max(a, b)` but avoids verbose type annotations.
    ///
    /// - Parameters:
    ///   - a: The first tagged value.
    ///   - b: The second tagged value.
    /// - Returns: The greater of `a` and `b`.
    @inlinable
    public static func max(_ a: Self, _ b: Self) -> Self {
        a._storage >= b._storage ? a : b
    }

    /// Returns the lesser of two tagged values.
    ///
    /// Equivalent to `Swift.min(a, b)` but avoids verbose type annotations.
    ///
    /// - Parameters:
    ///   - a: The first tagged value.
    ///   - b: The second tagged value.
    /// - Returns: The lesser of `a` and `b`.
    @inlinable
    public static func min(_ a: Self, _ b: Self) -> Self {
        a._storage <= b._storage ? a : b
    }
}
#endif

// MARK: - Functor (Static Implementation)

extension Tagged where Tag: ~Copyable & ~Escapable, Underlying: ~Copyable {
    /// Transforms the underlying value of a tagged value while preserving the tag.
    ///
    /// - Parameters:
    ///   - tagged: The tagged value to transform. Consumed.
    ///   - transform: A closure that transforms the underlying value.
    /// - Returns: A new tagged value with the same `Tag` and the transformed underlying.
    /// - Throws: The error thrown by `transform`, with type preserved.
    @inlinable
    public static func map<E: Error, NewUnderlying: ~Copyable>(
        _ tagged: consuming Tagged,
        transform: (consuming Underlying) throws(E) -> NewUnderlying
    ) throws(E) -> Tagged<Tag, NewUnderlying> {
        Tagged<Tag, NewUnderlying>(_unchecked: try transform(tagged._storage))
    }

    /// Changes the tag type while preserving the underlying value.
    ///
    /// This is a phantom coercion — it changes only the type-level tag with
    /// no effect on the stored value. With optimization, the compiler
    /// eliminates this call entirely.
    ///
    /// - Parameters:
    ///   - tagged: The tagged value to retag. Consumed.
    ///   - _: The new tag type (inferred when possible).
    /// - Returns: A new tagged value with `NewTag` and the same underlying.
    @inlinable
    public static func retag<NewTag: ~Copyable & ~Escapable>(
        _ tagged: consuming Tagged,
        to _: NewTag.Type = NewTag.self
    ) -> Tagged<NewTag, Underlying> {
        Tagged<NewTag, Underlying>(_unchecked: tagged._storage)
    }
}

// MARK: - Functor (Instance Convenience)

extension Tagged where Tag: ~Copyable & ~Escapable, Underlying: ~Copyable {
    /// Transforms the underlying value while preserving the tag.
    ///
    /// - Parameter transform: A closure that transforms the underlying value.
    /// - Returns: A new tagged value with the same `Tag` and the transformed underlying.
    /// - Throws: The error thrown by `transform`, with type preserved.
    @inlinable
    public consuming func map<E: Error, NewUnderlying: ~Copyable>(
        _ transform: (consuming Underlying) throws(E) -> NewUnderlying
    ) throws(E) -> Tagged<Tag, NewUnderlying> {
        try Self.map(self, transform: transform)
    }

    /// Changes the tag type while preserving the underlying value.
    ///
    /// - Parameter _: The new tag type (inferred when possible).
    /// - Returns: A new tagged value with `NewTag` and the same underlying.
    @inlinable
    public consuming func retag<NewTag: ~Copyable & ~Escapable>(_: NewTag.Type = NewTag.self) -> Tagged<NewTag, Underlying> {
        Self.retag(self, to: NewTag.self)
    }
}
