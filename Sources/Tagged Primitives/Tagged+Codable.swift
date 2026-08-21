#if !hasFeature(Embedded)
    extension Tagged: Codable
    where Tag: ~Copyable & ~Escapable, Underlying: Codable & Escapable {

        @inlinable
        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.init(_unchecked: try container.decode(Underlying.self))
        }

        @inlinable
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.underlying)
        }
    }
#endif
