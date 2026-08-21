extension Tagged: ExpressibleByIntegerLiteral
where Tag: ~Copyable & ~Escapable, Underlying: ExpressibleByIntegerLiteral {

    @_disfavoredOverload
    public init(integerLiteral value: Underlying.IntegerLiteralType) {
        self = .init(_unchecked: Underlying(integerLiteral: value))
    }
}

extension Tagged: ExpressibleByFloatLiteral
where Tag: ~Copyable & ~Escapable, Underlying: ExpressibleByFloatLiteral {

    @_disfavoredOverload
    public init(floatLiteral value: Underlying.FloatLiteralType) {
        self.init(_unchecked: Underlying(floatLiteral: value))
    }
}

extension Tagged: ExpressibleByUnicodeScalarLiteral
where Tag: ~Copyable & ~Escapable, Underlying: ExpressibleByUnicodeScalarLiteral {

    @_disfavoredOverload
    public init(unicodeScalarLiteral value: Underlying.UnicodeScalarLiteralType) {
        self.init(_unchecked: Underlying(unicodeScalarLiteral: value))
    }
}

extension Tagged: ExpressibleByExtendedGraphemeClusterLiteral
where Tag: ~Copyable & ~Escapable, Underlying: ExpressibleByExtendedGraphemeClusterLiteral {

    @_disfavoredOverload
    public init(extendedGraphemeClusterLiteral value: Underlying.ExtendedGraphemeClusterLiteralType)
    {
        self.init(_unchecked: Underlying(extendedGraphemeClusterLiteral: value))
    }
}

extension Tagged: ExpressibleByStringLiteral
where Tag: ~Copyable & ~Escapable, Underlying: ExpressibleByStringLiteral {

    @_disfavoredOverload
    public init(stringLiteral value: Underlying.StringLiteralType) {
        self.init(_unchecked: Underlying(stringLiteral: value))
    }
}

extension Tagged: ExpressibleByBooleanLiteral
where Tag: ~Copyable & ~Escapable, Underlying: ExpressibleByBooleanLiteral {

    @_disfavoredOverload
    public init(booleanLiteral value: Underlying.BooleanLiteralType) {
        self.init(_unchecked: Underlying(booleanLiteral: value))
    }
}

extension Tagged: ExpressibleByStringInterpolation
where Tag: ~Copyable & ~Escapable, Underlying: ExpressibleByStringInterpolation {

    @_disfavoredOverload
    public init(stringInterpolation: Underlying.StringInterpolation) {
        self.init(_unchecked: Underlying(stringInterpolation: stringInterpolation))
    }
}

extension Tagged: ExpressibleByArrayLiteral
where Tag: ~Copyable & ~Escapable, Underlying: ExpressibleByArrayLiteral {

    @_disfavoredOverload
    public init(arrayLiteral elements: Underlying.ArrayLiteralElement...) {
        let f = unsafe unsafeBitCast(
            Underlying.init(arrayLiteral:) as (Underlying.ArrayLiteralElement...) -> Underlying,
            to: (([Underlying.ArrayLiteralElement]) -> Underlying).self
        )
        self.init(_unchecked: f(elements))
    }
}

extension Tagged: ExpressibleByDictionaryLiteral
where Tag: ~Copyable & ~Escapable, Underlying: ExpressibleByDictionaryLiteral {

    @_disfavoredOverload
    public init(dictionaryLiteral elements: (Underlying.Key, Underlying.Value)...) {
        let f = unsafe unsafeBitCast(
            Underlying.init(dictionaryLiteral:)
                as ((Underlying.Key, Underlying.Value)...) -> Underlying,
            to: (([(Underlying.Key, Underlying.Value)]) -> Underlying).self
        )
        self.init(_unchecked: f(elements))
    }
}
