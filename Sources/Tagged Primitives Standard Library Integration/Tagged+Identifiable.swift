extension Tagged: Identifiable
where Tag: ~Copyable & ~Escapable, Underlying: Identifiable & Escapable {

    @inlinable
    public var id: Underlying.ID { underlying.id }
}
