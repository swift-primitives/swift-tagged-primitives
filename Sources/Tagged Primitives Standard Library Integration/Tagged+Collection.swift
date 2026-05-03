// Tagged+Collection.swift
// Opt-in `Collection` conformance for `Tagged<Tag, Underlying>` when
// `Underlying` is `Collection`. Forwards `startIndex`, `endIndex`,
// `subscript(position:)`, and `index(after:)` to the underlying
// underlying value.
//
// Empirically verified authorable on Swift 6.3.1 — see
// `Experiments/tagged-no-sequence-collection/` and
// `Research/principled-absence-sequence-collection.md`.
//
// Wrapper-vs-content conflation cost: see `Tagged+Sequence.swift`.

extension Tagged: Collection
where Tag: ~Copyable & ~Escapable, Underlying: Collection & Escapable {
    /// The index type of the wrapped collection.
    public typealias Index = Underlying.Index
    /// The element type of the wrapped collection.
    public typealias Element = Underlying.Element

    /// The position of the first element in a non-empty wrapped collection.
    @inlinable
    public var startIndex: Underlying.Index { _storage.startIndex }

    /// The collection's "past the end" position.
    @inlinable
    public var endIndex: Underlying.Index { _storage.endIndex }

    /// Accesses the element at the specified position.
    ///
    /// - Parameter position: A valid index of the wrapped collection.
    /// - Returns: The element at `position`, forwarded from
    ///   `_storage[position]`.
    @inlinable
    public subscript(position: Underlying.Index) -> Underlying.Element {
        _storage[position]
    }

    /// Returns the position immediately after the given index.
    ///
    /// - Parameter i: A valid index of the wrapped collection.
    /// - Returns: The next valid index, forwarded from
    ///   `_storage.index(after: i)`.
    @inlinable
    public func index(after i: Underlying.Index) -> Underlying.Index {
        _storage.index(after: i)
    }
}
