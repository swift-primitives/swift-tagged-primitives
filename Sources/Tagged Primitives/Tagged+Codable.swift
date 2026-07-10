// Tagged+Codable.swift
// Hand-written `Swift.Codable` conformance for `Tagged`.
//
// `Tagged` must encode and decode as the BARE underlying value — a single
// value — NOT as a keyed object `{"underlying": …}`. The compiler-synthesized
// conformance would derive from the stored `underlying` property and wrap it
// in a single-key container, so `Tagged<Customer, String>("cus_123")` would
// serialize as `{"underlying":"cus_123"}` instead of the JSON string
// `"cus_123"`. That breaks every consumer that round-trips a domain id through
// JSON and makes `Tagged<Tag, U>` wire-INcompatible with a bare `U`.
//
// The manual `singleValueContainer` implementation restores the transparent
// wire form: a `Tagged<Tag, U>` encodes/decodes as exactly what a bare `U`
// would. The `Underlying: Codable & Escapable` bound is preserved verbatim
// from the original conditional conformance (no `~Copyable` half — `Codable`
// composes over Copyable, Escapable underlyings only).
//
// Kept under `#if !hasFeature(Embedded)` — Embedded Swift excludes the
// existential-based `Codable` machinery — matching the pre-existing guard.

#if !hasFeature(Embedded)
    extension Tagged: Codable
    where Tag: ~Copyable & ~Escapable, Underlying: Codable & Escapable {
        /// Decodes a `Tagged` from the bare encoded form of its `Underlying`.
        ///
        /// Reads a single value (not a keyed container) so the wire form is
        /// transparent: a `Tagged<Tag, U>` decodes from exactly what a bare
        /// `U` would — the phantom `Tag` never appears on the wire.
        @inlinable
        // swiftlint:disable:next no_any_protocol_existential typed_throws_required - exact Decodable protocol requirement signature (stdlib; rule-exemptions protocol-requirement shape)
        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.init(_unchecked: try container.decode(Underlying.self))
        }

        /// Encodes a `Tagged` as the bare encoded form of its `Underlying`.
        ///
        /// Writes a single value (not a keyed container) so a `Tagged<Tag, U>`
        /// is wire-compatible with a bare `U`: e.g.
        /// `Tagged<Customer, String>("cus_123")` encodes as the JSON string
        /// `"cus_123"`, never `{"underlying":"cus_123"}`.
        @inlinable
        // swiftlint:disable:next no_any_protocol_existential typed_throws_required - exact Encodable protocol requirement signature (stdlib; rule-exemptions protocol-requirement shape)
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.underlying)
        }
    }
#endif
