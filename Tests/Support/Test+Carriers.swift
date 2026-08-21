public import Carrier_Primitives

extension Array: @retroactive Carrier.`Protocol` {

    public typealias Underlying = [Element]
}

extension ContiguousArray: @retroactive Carrier.`Protocol` {

    public typealias Underlying = ContiguousArray<Element>
}

extension Dictionary: @retroactive Carrier.`Protocol` {

    public typealias Underlying = [Key: Value]
}

extension Set: @retroactive Carrier.`Protocol` {

    public typealias Underlying = Set<Element>
}
