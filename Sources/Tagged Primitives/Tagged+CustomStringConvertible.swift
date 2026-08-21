extension Tagged: CustomStringConvertible
where Tag: ~Copyable & ~Escapable, Underlying: CustomStringConvertible & Escapable {

    @inlinable
    public var description: String { underlying.description }
}
