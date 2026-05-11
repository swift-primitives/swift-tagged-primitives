// Tagged+LosslessStringConvertible.swift
// Opt-in `LosslessStringConvertible` conformance for `Tagged<Tag, Underlying>`
// when `Underlying` is `LosslessStringConvertible`. Forwards
// `init?(_ description: String)` to `Underlying.init?(_:)`.
// The `description` requirement is satisfied by Tagged's existing
// `CustomStringConvertible` conformance in the main module.
//
// Empirically verified authorable on Swift 6.3.1 — see
// `Experiments/tagged-no-losslessstringconvertible/` and
// `Research/principled-absence-losslessstringconvertible.md`.
//
// Lossy-from-Tagged-perspective cost: the description encodes only
// `Underlying.description`, not the phantom Tag. A string '42' parses
// equally well into every `Tagged<_, Int>`; the receiver's type
// annotation determines the Tag, not the string content. Consumers
// serializing across wire/file/
// IPC where Tag must be preserved should prefer per-domain wrapper
// structs (see `Research/principled-absence-losslessstringconvertible.md`
// Option C).

extension Tagged: LosslessStringConvertible
where
    Tag: ~Copyable & ~Escapable,
    Underlying: LosslessStringConvertible & Escapable
{
    /// Parses a string into a tagged value by forwarding to `Underlying.init?(_:)`.
    ///
    /// Constructs a `Tagged` wrapping the parsed `Underlying`, or returns
    /// `nil` if parsing fails.
    ///
    /// The phantom `Tag` is determined by the receiver's type annotation,
    /// not by `description` content — serializing across wire/file/IPC
    /// where `Tag` must be preserved should prefer per-domain wrapper
    /// structs (see `Research/principled-absence-losslessstringconvertible.md`).
    ///
    /// - Parameter description: The string to parse.
    @inlinable
    public init?(_ description: String) {
        guard let raw = Underlying(description) else { return nil }
        self.init(_unchecked: raw)
    }
    // `var description: String { get }` requirement inherited from
    // `CustomStringConvertible` in the main `Tagged Primitives` module.
}
