// Tagged+Identifiable.swift
// Opt-in `Identifiable` conformance for `Tagged<Tag, Underlying>` when
// `Underlying` is `Identifiable`. Forwards `id` to `_storage.id`.
//
// Empirically verified authorable on Swift 6.3.1 — see
// `Experiments/tagged-no-identifiable/` and
// `Research/principled-absence-identifiable.md`.
//
// Identity-inversion cost: with this conformance, two Tagged values
// with different phantom Tags but the same `Underlying.id` are observed
// as the same id by Identifiable consumers. Consumers authoring their
// own domain types should prefer the Tagged-as-id pattern (see
// `Research/principled-absence-identifiable.md` Option C).

extension Tagged: Identifiable
where Tag: ~Copyable & ~Escapable, Underlying: Identifiable & Escapable {
    /// The identifier of the wrapped underlying value.
    ///
    /// Forwards to `_storage.id`. Two `Tagged` values with different
    /// phantom tags but the same `Underlying.id` produce the same `id` —
    /// this is the documented identity-inversion trade-off; see
    /// `Research/principled-absence-identifiable.md` for the full
    /// rationale and the Tagged-as-id alternative pattern.
    @inlinable
    public var id: Underlying.ID { _storage.id }
}
