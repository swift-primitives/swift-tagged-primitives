extension Tagged: Swift.Collection
where Tag: ~Copyable & ~Escapable, Underlying: Swift.Collection & Escapable {

    public typealias Index = Underlying.Index

    public typealias Element = Underlying.Element

    @inlinable
    public var startIndex: Underlying.Index { underlying.startIndex }

    @inlinable
    public var endIndex: Underlying.Index { underlying.endIndex }

    @inlinable
    public subscript(position: Underlying.Index) -> Underlying.Element {
        underlying[position]
    }

    @inlinable
    public func index(after i: Underlying.Index) -> Underlying.Index {
        underlying.index(after: i)
    }
}
