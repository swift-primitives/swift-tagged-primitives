// Tagged+Identifiable.swift
// Opt-in `Identifiable` conformance for `Tagged<Tag, RawValue>` when
// `RawValue` is `Identifiable`. Forwards `id` to `rawValue.id`.
//
// Empirically verified authorable on Swift 6.3.1 — see
// `Experiments/tagged-no-identifiable/` and
// `Research/principled-absence-identifiable.md`.
//
// Identity-inversion cost: with this conformance, two Tagged values
// with different phantom Tags but the same `RawValue.id` are observed
// as the same id by Identifiable consumers. Consumers authoring their
// own domain types should prefer the Tagged-as-id pattern (see
// `Research/principled-absence-identifiable.md` Option C).

extension Tagged: Identifiable
where Tag: ~Copyable & ~Escapable, RawValue: Identifiable & Escapable {
    /// The identifier of the wrapped raw value.
    ///
    /// Forwards to `rawValue.id`. Two `Tagged` values with different
    /// phantom tags but the same `RawValue.id` produce the same `id` —
    /// this is the documented identity-inversion trade-off; see
    /// `Research/principled-absence-identifiable.md` for the full
    /// rationale and the Tagged-as-id alternative pattern.
    @inlinable
    public var id: RawValue.ID { rawValue.id }
}
