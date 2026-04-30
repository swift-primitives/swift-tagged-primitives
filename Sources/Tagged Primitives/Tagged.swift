// Tagged.swift
// A phantom-type wrapper for type-safe value distinction.
//
// Inspired by swift-tagged by Point-Free (https://github.com/pointfreeco/swift-tagged)

/// A value wrapped with a compile-time phantom type tag.
///
/// `Tagged` provides zero-cost type safety by wrapping a raw value with a
/// phantom `Tag` parameter that exists only at compile time. The tag is
/// always an existing domain type — the domain itself is the discriminator.
///
/// The tag adds no runtime overhead — only the raw value is stored.
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
@frozen
public struct Tagged<Tag: ~Copyable & ~Escapable, RawValue: ~Copyable & ~Escapable>: ~Copyable, ~Escapable {
    /// The underlying raw value.
    ///
    /// Use this to access the wrapped value when needed for interop
    /// with non-Tagged APIs.
    public var rawValue: RawValue

    /// Creates a tagged value from a raw value.
    ///
    /// - Parameters:
    ///   - __unchecked: Disambiguation label signaling no domain validation.
    ///   - rawValue: The raw value to wrap.
    ///
    /// - Note: Domain types should provide their own
    ///   validated initializers and use this internally.
    @inlinable
    @_lifetime(copy rawValue)
    public init(__unchecked: Void, _ rawValue: consuming RawValue) {
        self.rawValue = rawValue
    }
}

// MARK: - `modify`

// `modify` uses an `inout RawValue` closure parameter and is available for
// any combination of Copyable / Escapable on RawValue. The historical
// Swift 6.3 "closure-parameter-lifetime gap for ~Escapable types" was
// revalidated FIXED on Swift 6.3.1 — see
// Experiments/tagged-modify-escapable-revalidation (CONFIRMED, 2026-04-24).
extension Tagged where Tag: ~Copyable & ~Escapable, RawValue: ~Copyable & ~Escapable {
    @inlinable
    package mutating func modify<T>(_ body: (_ rawValue: inout RawValue) -> T) -> T {
        body(&self.rawValue)
    }
}

// MARK: - Conditional Copyable / Escapable

// Tagged admits ~Escapable RawValue. Whether a Tagged instance is Copyable or
// Escapable is derived from the RawValue's independent capabilities.

extension Tagged: Copyable where Tag: ~Copyable & ~Escapable, RawValue: Copyable & ~Escapable {}
extension Tagged: Escapable where Tag: ~Copyable & ~Escapable, RawValue: Escapable & ~Copyable {}

// MARK: - Conditional Conformances (Swift Standard Library)

// These conformances are restricted to Escapable RawValue. They preserve the
// exact pre-generalization behavior: every RawValue that conformed before
// (e.g., Int, String, domain structs) still conforms; ~Escapable RawValues
// (e.g., Ownership.Inout<Base>) do not participate here.

extension Tagged: Sendable
    where Tag: ~Copyable & ~Escapable, RawValue: ~Copyable & Sendable & Escapable {}

// `BitwiseCopyable` does not currently admit `~Copyable`, so `Escapable` is
// required here on Swift 6.3.1. When `BitwiseCopyable` is widened to admit
// `~Copyable` (the natural next step on the SE-04XX suppressed-protocol
// generality line), revisit this constraint to drop the `& Escapable` half.
extension Tagged: BitwiseCopyable
    where Tag: ~Copyable & ~Escapable, RawValue: BitwiseCopyable & Escapable {}

// SE-0499: Swift.Equatable, Swift.Hashable, Swift.Comparable no longer imply
// Copyable in Swift 6.4. The & ~Copyable suppression lets these conformances
// apply to ~Copyable RawValue types.
#if compiler(>=6.4)
extension Tagged: Equatable
    where Tag: ~Copyable & ~Escapable, RawValue: Equatable & ~Copyable & Escapable {}
extension Tagged: Hashable
    where Tag: ~Copyable & ~Escapable, RawValue: Hashable & ~Copyable & Escapable {}
#else
extension Tagged: Equatable
    where Tag: ~Copyable & ~Escapable, RawValue: Equatable & Escapable {}
extension Tagged: Hashable
    where Tag: ~Copyable & ~Escapable, RawValue: Hashable & Escapable {}
#endif

#if !hasFeature(Embedded)
    extension Tagged: Codable
        where Tag: ~Copyable & ~Escapable, RawValue: Codable & Escapable {}
#endif

#if compiler(>=6.4)
extension Tagged: Comparable
    where Tag: ~Copyable & ~Escapable, RawValue: Comparable & ~Copyable & Escapable {
    @inlinable
    public static func < (lhs: borrowing Tagged, rhs: borrowing Tagged) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Returns the greater of two tagged values.
    ///
    /// - Parameters:
    ///   - a: The first tagged value.
    ///   - b: The second tagged value.
    /// - Returns: The greater of `a` and `b`.
    @inlinable
    public static func max(_ a: consuming Self, _ b: consuming Self) -> Self {
        a.rawValue >= b.rawValue ? a : b
    }

    /// Returns the lesser of two tagged values.
    ///
    /// - Parameters:
    ///   - a: The first tagged value.
    ///   - b: The second tagged value.
    /// - Returns: The lesser of `a` and `b`.
    @inlinable
    public static func min(_ a: consuming Self, _ b: consuming Self) -> Self {
        a.rawValue <= b.rawValue ? a : b
    }
}
#else
extension Tagged: Comparable
    where Tag: ~Copyable & ~Escapable, RawValue: Comparable & Escapable {
    @inlinable
    public static func < (lhs: Tagged, rhs: Tagged) -> Bool {
        lhs.rawValue < rhs.rawValue
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
        a.rawValue >= b.rawValue ? a : b
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
        a.rawValue <= b.rawValue ? a : b
    }
}
#endif

// MARK: - Functor (Static Implementation)

extension Tagged where Tag: ~Copyable & ~Escapable, RawValue: ~Copyable {
    /// Transforms the raw value of a tagged value while preserving the tag.
    ///
    /// - Parameters:
    ///   - tagged: The tagged value to transform. Consumed.
    ///   - transform: A closure that transforms the raw value.
    /// - Returns: A new tagged value with the same `Tag` and the transformed raw value.
    /// - Throws: The error thrown by `transform`, with type preserved.
    @inlinable
    public static func map<E: Error, NewRawValue: ~Copyable>(
        _ tagged: consuming Tagged,
        transform: (consuming RawValue) throws(E) -> NewRawValue
    ) throws(E) -> Tagged<Tag, NewRawValue> {
        Tagged<Tag, NewRawValue>(__unchecked: (), try transform(tagged.rawValue))
    }

    /// Changes the tag type while preserving the raw value.
    ///
    /// This is a phantom coercion — it changes only the type-level tag with
    /// no effect on the stored value. With optimization, the compiler
    /// eliminates this call entirely.
    ///
    /// - Parameters:
    ///   - tagged: The tagged value to retag. Consumed.
    ///   - _: The new tag type (inferred when possible).
    /// - Returns: A new tagged value with `NewTag` and the same raw value.
    @inlinable
    public static func retag<NewTag: ~Copyable & ~Escapable>(
        _ tagged: consuming Tagged,
        to _: NewTag.Type = NewTag.self
    ) -> Tagged<NewTag, RawValue> {
        Tagged<NewTag, RawValue>(__unchecked: (), tagged.rawValue)
    }
}

// MARK: - Functor (Instance Convenience)

extension Tagged where Tag: ~Copyable & ~Escapable, RawValue: ~Copyable {
    /// Transforms the raw value while preserving the tag.
    ///
    /// - Parameter transform: A closure that transforms the raw value.
    /// - Returns: A new tagged value with the same `Tag` and the transformed raw value.
    /// - Throws: The error thrown by `transform`, with type preserved.
    @inlinable
    public consuming func map<E: Error, NewRawValue: ~Copyable>(
        _ transform: (consuming RawValue) throws(E) -> NewRawValue
    ) throws(E) -> Tagged<Tag, NewRawValue> {
        try Self.map(self, transform: transform)
    }

    /// Changes the tag type while preserving the raw value.
    ///
    /// - Parameter _: The new tag type (inferred when possible).
    /// - Returns: A new tagged value with `NewTag` and the same raw value.
    @inlinable
    public consuming func retag<NewTag: ~Copyable & ~Escapable>(_: NewTag.Type = NewTag.self) -> Tagged<NewTag, RawValue> {
        Self.retag(self, to: NewTag.self)
    }
}
