// Test+Carriers.swift
//
// Trivial self-carrier conformances for stdlib collection types used in
// the Tagged test suite. These conformances live in Test Support — NOT in
// `Carrier Primitives Standard Library Integration` — because the central
// SLI deliberately skips them per:
//
//   - swift-carrier-primitives/Research/sli-array.md (DECISION: skipped)
//   - swift-carrier-primitives/Research/sli-set.md
//   - swift-carrier-primitives/Research/sli-dictionary.md
//   - swift-carrier-primitives/Research/sli-contiguousarray.md
//
// The decision rationale: trivial-self-carrier of a collection has zero
// semantic payoff at module-public scope (no phantom-tag dimension is
// added), and shipping a parametric form would lock a Domain choice that
// downstream consumers should make for themselves.
//
// For the Tagged test suite, however, we want to exercise generic
// Carrier-based code over `Tagged<Tag, [Int]>` and friends, plus
// occasionally pass bare collections to `some Carrier.\`Protocol\``-
// constrained APIs. Test Support is the appropriate scope.

public import Carrier_Primitives

extension Array: @retroactive Carrier.`Protocol` {
    /// Trivial self-carrier: the underlying value is the array itself.
    public typealias Underlying = [Element]
}

extension ContiguousArray: @retroactive Carrier.`Protocol` {
    /// Trivial self-carrier: the underlying value is the contiguous array itself.
    public typealias Underlying = ContiguousArray<Element>
}

extension Dictionary: @retroactive Carrier.`Protocol` {
    /// Trivial self-carrier: the underlying value is the dictionary itself.
    public typealias Underlying = [Key: Value]
}

extension Set: @retroactive Carrier.`Protocol` {
    /// Trivial self-carrier: the underlying value is the set itself.
    public typealias Underlying = Set<Element>
}
