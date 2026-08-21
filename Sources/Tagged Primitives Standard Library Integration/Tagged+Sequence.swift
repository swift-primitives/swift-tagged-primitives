extension Tagged: Swift.Sequence
where Tag: ~Copyable & ~Escapable, Underlying: Swift.Sequence & Escapable {

    @inlinable
    public func makeIterator() -> Underlying.Iterator {
        underlying.makeIterator()
    }
}
