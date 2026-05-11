// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives
// project authors. Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

#if SYNCHRONIZATION_AVAILABLE
    public import Synchronization

    // MARK: - Tagged + AtomicRepresentable

    /// Tagged inherits AtomicRepresentable from its Underlying.
    ///
    /// One generic conformance covers every `Tagged<Tag, Underlying>` whose
    /// `Underlying` itself conforms to AtomicRepresentable. Downstream packages
    /// (cardinal, ordinal, ...) conform their concrete `Underlying` once; the
    /// Tagged form follows automatically — no per-Underlying retroactive
    /// conformance, no duplicate-conformance conflicts when multiple downstream
    /// packages are imported together.
    extension Tagged: AtomicRepresentable
    where Underlying: AtomicRepresentable, Tag: ~Copyable {
        /// Inherits the storage representation from `Underlying`.
        public typealias AtomicRepresentation = Underlying.AtomicRepresentation

        /// Encodes a tagged value into its atomic storage representation by
        /// delegating to the underlying value's encoder.
        @inlinable
        public static func encodeAtomicRepresentation(
            _ value: consuming Self
        ) -> AtomicRepresentation {
            Underlying.encodeAtomicRepresentation(value.underlying)
        }

        /// Decodes an atomic storage representation back into a tagged value by
        /// delegating to the underlying value's decoder.
        @inlinable
        public static func decodeAtomicRepresentation(
            _ representation: consuming AtomicRepresentation
        ) -> Self {
            Self(Underlying.decodeAtomicRepresentation(representation))
        }
    }
#endif
