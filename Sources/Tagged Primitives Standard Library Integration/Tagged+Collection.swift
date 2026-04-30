// Tagged+Collection.swift
// Opt-in `Collection` conformance for `Tagged<Tag, RawValue>` when
// `RawValue` is `Collection`. Forwards `startIndex`, `endIndex`,
// `subscript(position:)`, and `index(after:)` to the underlying
// raw value.
//
// Empirically verified authorable on Swift 6.3.1 — see
// `Experiments/tagged-no-sequence-collection/` and
// `Research/principled-absence-sequence-collection.md`.
//
// Wrapper-vs-content conflation cost: see `Tagged+Sequence.swift`.

extension Tagged: Collection
where Tag: ~Copyable & ~Escapable, RawValue: Collection & Escapable {
    /// The index type of the wrapped collection.
    public typealias Index = RawValue.Index
    /// The element type of the wrapped collection.
    public typealias Element = RawValue.Element

    /// The position of the first element in a non-empty wrapped collection.
    @inlinable
    public var startIndex: RawValue.Index { rawValue.startIndex }

    /// The collection's "past the end" position.
    @inlinable
    public var endIndex: RawValue.Index { rawValue.endIndex }

    /// Accesses the element at the specified position.
    ///
    /// - Parameter position: A valid index of the wrapped collection.
    /// - Returns: The element at `position`, forwarded from
    ///   `rawValue[position]`.
    @inlinable
    public subscript(position: RawValue.Index) -> RawValue.Element {
        rawValue[position]
    }

    /// Returns the position immediately after the given index.
    ///
    /// - Parameter i: A valid index of the wrapped collection.
    /// - Returns: The next valid index, forwarded from
    ///   `rawValue.index(after: i)`.
    @inlinable
    public func index(after i: RawValue.Index) -> RawValue.Index {
        rawValue.index(after: i)
    }
}
