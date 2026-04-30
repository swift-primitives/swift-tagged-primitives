// Tagged+Sequence.swift
// Opt-in `Sequence` conformance for `Tagged<Tag, RawValue>` when
// `RawValue` is `Sequence`. Forwards `makeIterator()` to the underlying
// raw value.
//
// Empirically verified authorable on Swift 6.3.1 — see
// `Experiments/tagged-no-sequence-collection/` and
// `Research/principled-absence-sequence-collection.md`.
//
// Wrapper-vs-content conflation cost: with this conformance, generic
// algorithms over `T: Sequence` treat `Tagged<Tag, [E]>` and `[E]`
// interchangeably — the phantom Tag becomes invisible to the algorithm.
// The default-safe pattern (explicit `tagged.rawValue.forEach { … }`)
// preserves wrapper-boundary visibility; consumers importing this SLI
// accept the conflation cost in exchange for stdlib-Sequence ergonomics.

extension Tagged: Sequence
where Tag: ~Copyable & ~Escapable, RawValue: Sequence & Escapable {
    /// Returns an iterator over the wrapped raw value.
    ///
    /// Forwards to `rawValue.makeIterator()`. Generic algorithms over
    /// `T: Sequence` will treat `Tagged<Tag, [E]>` and `[E]`
    /// interchangeably — the phantom `Tag` is invisible to the algorithm.
    /// Consumers needing wrapper-boundary visibility should prefer
    /// `tagged.rawValue.forEach { … }` instead.
    @inlinable
    public func makeIterator() -> RawValue.Iterator {
        rawValue.makeIterator()
    }
}
