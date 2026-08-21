@frozen
public struct Tagged<Tag: ~Copyable & ~Escapable, Underlying: ~Copyable & ~Escapable>: ~Copyable,
    ~Escapable
{

    public package(set) var underlying: Underlying

    @_lifetime(copy underlying)
    public init(_unchecked underlying: consuming Underlying) {
        self.underlying = underlying
    }
}

extension Tagged where Tag: ~Copyable & ~Escapable, Underlying: ~Copyable & ~Escapable {
    package mutating func modify<T>(_ body: (_ underlying: inout Underlying) -> T) -> T {
        body(&self.underlying)
    }
}

extension Tagged: Copyable where Tag: ~Copyable & ~Escapable, Underlying: Copyable & ~Escapable {}
extension Tagged: Escapable where Tag: ~Copyable & ~Escapable, Underlying: Escapable & ~Copyable {}

extension Tagged: Sendable
where Tag: ~Copyable & ~Escapable, Underlying: ~Copyable & Sendable & Escapable {}

extension Tagged: BitwiseCopyable
where Tag: ~Copyable & ~Escapable, Underlying: BitwiseCopyable & Escapable {}

extension Tagged: Equatable
where Tag: ~Copyable & ~Escapable, Underlying: Equatable & ~Copyable & Escapable {}
extension Tagged: Hashable
where Tag: ~Copyable & ~Escapable, Underlying: Hashable & ~Copyable & Escapable {}

extension Tagged: Comparable
where Tag: ~Copyable & ~Escapable, Underlying: Comparable & ~Copyable & Escapable {

    @inlinable
    public static func < (lhs: borrowing Tagged, rhs: borrowing Tagged) -> Bool {
        lhs.underlying < rhs.underlying
    }

    @inlinable
    public static func max(_ a: consuming Self, _ b: consuming Self) -> Self {
        a.underlying >= b.underlying ? a : b
    }

    @inlinable
    public static func min(_ a: consuming Self, _ b: consuming Self) -> Self {
        a.underlying <= b.underlying ? a : b
    }
}

extension Tagged where Tag: ~Copyable & ~Escapable, Underlying: ~Copyable {

    @inlinable
    public static func map<E: Swift.Error, NewUnderlying: ~Copyable>(
        _ tagged: consuming Tagged,
        transform: (consuming Underlying) throws(E) -> NewUnderlying
    ) throws(E) -> Tagged<Tag, NewUnderlying> {
        Tagged<Tag, NewUnderlying>(_unchecked: try transform(tagged.underlying))
    }

    @inlinable
    public static func retag<New: ~Copyable & ~Escapable>(
        _ tagged: consuming Tagged,
        to _: New.Type = New.self
    ) -> Tagged<New, Underlying> {
        Tagged<New, Underlying>(_unchecked: tagged.underlying)
    }
}

extension Tagged where Tag: ~Copyable & ~Escapable, Underlying: ~Copyable {

    @inlinable
    public consuming func map<E: Swift.Error, NewUnderlying: ~Copyable>(
        _ transform: (consuming Underlying) throws(E) -> NewUnderlying
    ) throws(E) -> Tagged<Tag, NewUnderlying> {
        try Self.map(self, transform: transform)
    }

    @inlinable
    public consuming func retag<New: ~Copyable & ~Escapable>(
        _: New.Type = New.self
    ) -> Tagged<New, Underlying> {
        Self.retag(self, to: New.self)
    }
}
