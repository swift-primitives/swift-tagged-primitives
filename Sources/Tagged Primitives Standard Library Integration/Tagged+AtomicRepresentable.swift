#if SYNCHRONIZATION_AVAILABLE
    public import Synchronization

    extension Tagged: AtomicRepresentable
    where Underlying: AtomicRepresentable, Tag: ~Copyable & ~Escapable {

        public typealias AtomicRepresentation = Underlying.AtomicRepresentation

        @inlinable
        public static func encodeAtomicRepresentation(
            _ value: consuming Self
        ) -> AtomicRepresentation {
            Underlying.encodeAtomicRepresentation(value.underlying)
        }

        @inlinable
        public static func decodeAtomicRepresentation(
            _ representation: consuming AtomicRepresentation
        ) -> Self {
            Self(Underlying.decodeAtomicRepresentation(representation))
        }
    }
#endif
