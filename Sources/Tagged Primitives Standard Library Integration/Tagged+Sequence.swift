// Tagged+Sequence.swift
// Opt-in `Sequence` conformance for `Tagged<Tag, Underlying>` when
// `Underlying` is `Sequence`. Forwards `makeIterator()` to the underlying
// underlying value.
//
// Empirically verified authorable on Swift 6.3.1 — see
// `Experiments/tagged-no-sequence-collection/` and
// `Research/principled-absence-sequence-collection.md`.
//
// Wrapper-vs-content conflation cost: with this conformance, generic
// algorithms over `T: Sequence` treat `Tagged<Tag, [E]>` and `[E]`
// interchangeably — the phantom Tag becomes invisible to the algorithm.
// The default-safe pattern (explicit `tagged._storage.forEach { … }`)
// preserves wrapper-boundary visibility; consumers importing this SLI
// accept the conflation cost in exchange for stdlib-Sequence ergonomics.

extension Tagged: Sequence
where Tag: ~Copyable & ~Escapable, Underlying: Sequence & Escapable {
    /// Returns an iterator over the wrapped underlying value.
    ///
    /// Forwards to `_storage.makeIterator()`. Generic algorithms over
    /// `T: Sequence` will treat `Tagged<Tag, [E]>` and `[E]`
    /// interchangeably — the phantom `Tag` is invisible to the algorithm.
    /// Consumers needing wrapper-boundary visibility should prefer
    /// `tagged._storage.forEach { … }` instead.
    @inlinable
    public func makeIterator() -> Underlying.Iterator {
        _storage.makeIterator()
    }
}
