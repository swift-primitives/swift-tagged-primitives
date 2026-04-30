// Tagged+LosslessStringConvertible.swift
// Opt-in `LosslessStringConvertible` conformance for `Tagged<Tag, RawValue>`
// when `RawValue` is `LosslessStringConvertible`. Forwards
// `init?(_ description: String)` to `RawValue.init?(_:)`.
// The `description` requirement is satisfied by Tagged's existing
// `CustomStringConvertible` conformance in the main module.
//
// Empirically verified authorable on Swift 6.3.1 — see
// `Experiments/tagged-no-losslessstringconvertible/` and
// `Research/principled-absence-losslessstringconvertible.md`.
//
// Lossy-from-Tagged-perspective cost: the description encodes only
// `RawValue.description`, not the phantom Tag. A string '42' parses as
// any Tagged<Tag, Int>; the receiver's type annotation determines the
// Tag, not the string content. Consumers serializing across wire/file/
// IPC where Tag must be preserved should prefer per-domain wrapper
// structs (see `Research/principled-absence-losslessstringconvertible.md`
// Option C).

extension Tagged: LosslessStringConvertible
where Tag: ~Copyable & ~Escapable,
      RawValue: LosslessStringConvertible & Escapable {
    /// Parses a string into a tagged value by forwarding to
    /// `RawValue.init?(_:)`.
    ///
    /// - Parameter description: The string to parse.
    /// - Returns: A `Tagged` wrapping the parsed `RawValue`, or `nil`
    ///   if parsing fails. The phantom `Tag` is determined by the
    ///   receiver's type annotation, not by `description` content —
    ///   serializing across wire/file/IPC where `Tag` must be preserved
    ///   should prefer per-domain wrapper structs (see
    ///   `Research/principled-absence-losslessstringconvertible.md`).
    @inlinable
    public init?(_ description: String) {
        guard let raw = RawValue(description) else { return nil }
        self.init(__unchecked: (), raw)
    }
    // `var description: String { get }` requirement inherited from
    // `CustomStringConvertible` in the main `Tagged Primitives` module.
}
