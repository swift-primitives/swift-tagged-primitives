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
// The default-safe pattern (explicit `tagged.underlying.forEach { … }`)
// preserves wrapper-boundary visibility; consumers importing this SLI
// accept the conflation cost in exchange for stdlib-Sequence ergonomics.

extension Tagged: Swift.Sequence
where Tag: ~Copyable & ~Escapable, Underlying: Swift.Sequence & Escapable {
    /// Returns an iterator over the wrapped underlying value.
    ///
    /// Forwards to `underlying.makeIterator()`. Generic algorithms over
    /// `T: Sequence` will treat `Tagged<Tag, [E]>` and `[E]`
    /// interchangeably — the phantom `Tag` is invisible to the algorithm.
    /// Consumers needing wrapper-boundary visibility should prefer
    /// `tagged.underlying.forEach { … }` instead.
    ///
    /// `makeIterator()` is the protocol-required member of `Swift.Sequence`
    /// and cannot be renamed without breaking conformance, even though the
    /// ecosystem otherwise prefers nested-accessor naming.
    @inlinable
    public func makeIterator() -> Underlying.Iterator {
        underlying.makeIterator()
    }
}
