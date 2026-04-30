import Testing
@testable import Tagged_Primitives
import Tagged_Primitives_Standard_Library_Integration
import Tagged_Primitives_Test_Support

// Tagged is generic — parallel namespace pattern per [SWIFT-TEST-003].

private enum Tag1 {}
private enum Tag2 {}
private enum Tag3 {}

// MARK: - Tagged

@Suite
struct `Tagged Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit

extension `Tagged Tests`.Unit {

    // MARK: Construction

    @Test
    func `init stores raw value`() {
        let tagged: Tagged<Tag1, Int> = 42
        #expect(tagged.rawValue == 42)
    }

    @Test
    func `integer literal construction`() {
        let tagged: Tagged<Tag1, Int> = 99
        #expect(tagged.rawValue == 99)
    }

    @Test
    func `string literal construction`() {
        let tagged: Tagged<Tag1, String> = "hello"
        #expect(tagged.rawValue == "hello")
    }

    @Test
    func `boolean literal construction`() {
        let tagged: Tagged<Tag1, Bool> = true
        #expect(tagged.rawValue == true)
    }

    @Test
    func `float literal construction`() {
        let tagged: Tagged<Tag1, Double> = 3.14
        #expect(tagged.rawValue == 3.14)
    }

    // MARK: Zero-Cost Layout

    @Test
    func `Tagged Int has same MemoryLayout as Int`() {
        #expect(MemoryLayout<Tagged<Tag1, Int>>.size == MemoryLayout<Int>.size)
        #expect(MemoryLayout<Tagged<Tag1, Int>>.stride == MemoryLayout<Int>.stride)
        #expect(MemoryLayout<Tagged<Tag1, Int>>.alignment == MemoryLayout<Int>.alignment)
    }

    @Test
    func `Tagged UInt8 has same MemoryLayout as UInt8`() {
        #expect(MemoryLayout<Tagged<Tag1, UInt8>>.size == MemoryLayout<UInt8>.size)
        #expect(MemoryLayout<Tagged<Tag1, UInt8>>.stride == MemoryLayout<UInt8>.stride)
        #expect(MemoryLayout<Tagged<Tag1, UInt8>>.alignment == MemoryLayout<UInt8>.alignment)
    }

    @Test
    func `Tagged Double has same MemoryLayout as Double`() {
        #expect(MemoryLayout<Tagged<Tag1, Double>>.size == MemoryLayout<Double>.size)
        #expect(MemoryLayout<Tagged<Tag1, Double>>.stride == MemoryLayout<Double>.stride)
        #expect(MemoryLayout<Tagged<Tag1, Double>>.alignment == MemoryLayout<Double>.alignment)
    }

    @Test
    func `Tagged Bool has same MemoryLayout as Bool`() {
        #expect(MemoryLayout<Tagged<Tag1, Bool>>.size == MemoryLayout<Bool>.size)
        #expect(MemoryLayout<Tagged<Tag1, Bool>>.stride == MemoryLayout<Bool>.stride)
        #expect(MemoryLayout<Tagged<Tag1, Bool>>.alignment == MemoryLayout<Bool>.alignment)
    }

    @Test
    func `Tagged UInt64 has same MemoryLayout as UInt64`() {
        #expect(MemoryLayout<Tagged<Tag1, UInt64>>.size == MemoryLayout<UInt64>.size)
        #expect(MemoryLayout<Tagged<Tag1, UInt64>>.stride == MemoryLayout<UInt64>.stride)
        #expect(MemoryLayout<Tagged<Tag1, UInt64>>.alignment == MemoryLayout<UInt64>.alignment)
    }

    @Test
    func `different tags produce identical layout`() {
        #expect(MemoryLayout<Tagged<Tag1, Int>>.size == MemoryLayout<Tagged<Tag2, Int>>.size)
        #expect(MemoryLayout<Tagged<Tag1, Int>>.stride == MemoryLayout<Tagged<Tag2, Int>>.stride)
        #expect(MemoryLayout<Tagged<Tag1, Int>>.alignment == MemoryLayout<Tagged<Tag2, Int>>.alignment)
    }

    // MARK: rawValue

    @Test
    func `rawValue read returns stored value`() {
        let tagged: Tagged<Tag1, Int> = 7
        #expect(tagged.rawValue == 7)
    }

    @Test
    func `rawValue modify mutates in place`() {
        var tagged: Tagged<Tag1, Int> = 10
        tagged.rawValue += 5
        #expect(tagged.rawValue == 15)
    }

    // MARK: modify (package-internal)

    @Test
    func `modify mutates raw value via closure`() {
        var tagged: Tagged<Tag1, Int> = 10
        let result = tagged.modify { value in
            value *= 3
            return value
        }
        #expect(result == 30)
        #expect(tagged.rawValue == 30)
    }

    // MARK: Equatable

    @Test
    func `equal raw values are equal`() {
        let a: Tagged<Tag1, Int> = 42
        let b: Tagged<Tag1, Int> = 42
        #expect(a == b)
    }

    @Test
    func `different raw values are not equal`() {
        let a: Tagged<Tag1, Int> = 1
        let b: Tagged<Tag1, Int> = 2
        #expect(a != b)
    }

    // MARK: Hashable

    @Test
    func `equal values hash equally`() {
        let a: Tagged<Tag1, Int> = 42
        let b: Tagged<Tag1, Int> = 42
        #expect(a.hashValue == b.hashValue)
    }

    // MARK: Comparable

    @Test
    func `less than compares raw values`() {
        let a: Tagged<Tag1, Int> = 1
        let b: Tagged<Tag1, Int> = 2
        #expect(a < b)
        #expect(!(b < a))
    }

    @Test
    func `max returns greater value`() {
        let a: Tagged<Tag1, Int> = 10
        let b: Tagged<Tag1, Int> = 20
        #expect(Tagged<Tag1, Int>.max(a, b) == b)
    }

    @Test
    func `min returns lesser value`() {
        let a: Tagged<Tag1, Int> = 10
        let b: Tagged<Tag1, Int> = 20
        #expect(Tagged<Tag1, Int>.min(a, b) == a)
    }

    // MARK: map

    @Test
    func `instance map transforms raw value preserving tag`() {
        let tagged: Tagged<Tag1, Int> = 5
        let result = tagged.map { $0 * 2 }
        #expect(result == 10)
    }

    @Test
    func `static map transforms raw value preserving tag`() {
        let tagged: Tagged<Tag1, Int> = 5
        let result = Tagged<Tag1, Int>.map(tagged) { $0 * 2 }
        #expect(result == 10)
    }

    @Test
    func `map changes raw value type`() {
        let tagged: Tagged<Tag1, Int> = 42
        let result: Tagged<Tag1, String> = tagged.map { String($0) }
        #expect(result.rawValue == "42")
    }

    // MARK: retag

    @Test
    func `instance retag changes tag preserving raw value`() {
        let tagged: Tagged<Tag1, Int> = 42
        let retagged: Tagged<Tag2, Int> = tagged.retag()
        #expect(retagged.rawValue == 42)
    }

    @Test
    func `static retag changes tag preserving raw value`() {
        let tagged: Tagged<Tag1, Int> = 42
        let retagged = Tagged<Tag1, Int>.retag(tagged, to: Tag2.self)
        #expect(retagged.rawValue == 42)
    }

    // MARK: CustomStringConvertible

    @Test
    func `description forwards to raw value`() {
        let tagged: Tagged<Tag1, Int> = 42
        #expect(tagged.description == "42")
    }

    @Test
    func `string description forwards to raw value`() {
        let tagged: Tagged<Tag1, String> = "hello"
        #expect(tagged.description == "hello")
    }

}

// MARK: - EdgeCase

extension `Tagged Tests`.`Edge Case` {

    // MARK: Comparable — total order properties

    @Test
    func `less than is irreflexive`() {
        let a: Tagged<Tag1, Int> = 5
        #expect(!(a < a))
    }

    @Test
    func `less than is asymmetric`() {
        let a: Tagged<Tag1, Int> = 1
        let b: Tagged<Tag1, Int> = 2
        #expect(a < b)
        #expect(!(b < a))
    }

    @Test
    func `less than is transitive`() {
        let a: Tagged<Tag1, Int> = 1
        let b: Tagged<Tag1, Int> = 2
        let c: Tagged<Tag1, Int> = 3
        #expect(a < b)
        #expect(b < c)
        #expect(a < c)
    }

    @Test
    func `equality implies not less than in either direction`() {
        let a: Tagged<Tag1, Int> = 5
        let b: Tagged<Tag1, Int> = 5
        #expect(a == b)
        #expect(!(a < b))
        #expect(!(b < a))
    }

    // MARK: max / min edge cases

    @Test
    func `max with equal values returns first`() {
        let a: Tagged<Tag1, Int> = 5
        let b: Tagged<Tag1, Int> = 5
        let result = Tagged<Tag1, Int>.max(a, b)
        #expect(result == a)
    }

    @Test
    func `min with equal values returns first`() {
        let a: Tagged<Tag1, Int> = 5
        let b: Tagged<Tag1, Int> = 5
        let result = Tagged<Tag1, Int>.min(a, b)
        #expect(result == a)
    }

    // MARK: map edge cases

    @Test
    func `map with throwing transform propagates error`() {
        enum TestError: Error { case expected }
        let tagged: Tagged<Tag1, Int> = 42
        #expect(throws: TestError.self) {
            try tagged.map { _ throws(TestError) -> String in throw .expected }
        }
    }

    @Test
    func `map identity law — map(id) equals id`() {
        let tagged: Tagged<Tag1, Int> = 99
        let result = tagged.map { $0 }
        #expect(result == tagged)
    }

    @Test
    func `map composition law — map(f∘g) equals map(f)∘map(g)`() {
        let tagged: Tagged<Tag1, Int> = 7
        let f: (Int) -> Int = { $0 + 10 }
        let g: (Int) -> Int = { $0 * 3 }

        let composed = tagged.map { f(g($0)) }
        let chained = tagged.map(g).map(f)
        #expect(composed == chained)
    }

    // MARK: retag edge cases

    @Test
    func `retag round-trip preserves value`() {
        let original: Tagged<Tag1, Int> = 42
        let retagged: Tagged<Tag2, Int> = original.retag()
        let restored: Tagged<Tag1, Int> = retagged.retag()
        #expect(restored == original)
    }

    @Test
    func `retag is associative across three tags`() {
        let a: Tagged<Tag1, Int> = 42
        let b: Tagged<Tag2, Int> = a.retag()
        let c: Tagged<Tag3, Int> = b.retag()
        let direct: Tagged<Tag3, Int> = a.retag()
        #expect(c.rawValue == direct.rawValue)
    }

    // MARK: Boundary raw values

    @Test
    func `zero raw value`() {
        let tagged: Tagged<Tag1, Int> = 0
        #expect(tagged.rawValue == 0)
        #expect(tagged == 0)
    }

    @Test
    func `negative raw value`() {
        let tagged: Tagged<Tag1, Int> = -42
        #expect(tagged.rawValue == -42)
    }

    @Test
    func `empty string raw value`() {
        let tagged: Tagged<Tag1, String> = ""
        #expect(tagged.rawValue.isEmpty)
        #expect(tagged.description.isEmpty)
    }
}

// MARK: - Integration

extension `Tagged Tests`.Integration {

    // MARK: Instance-static equivalence

    @Test
    func `instance map produces same result as static map`() {
        let a: Tagged<Tag1, Int> = 42
        let b: Tagged<Tag1, Int> = 42
        let instanceResult = a.map { $0 * 2 }
        let staticResult = Tagged<Tag1, Int>.map(b) { $0 * 2 }
        #expect(instanceResult == staticResult)
    }

    @Test
    func `instance retag produces same result as static retag`() {
        let a: Tagged<Tag1, Int> = 42
        let b: Tagged<Tag1, Int> = 42
        let instanceResult: Tagged<Tag2, Int> = a.retag()
        let staticResult = Tagged<Tag1, Int>.retag(b, to: Tag2.self)
        #expect(instanceResult.rawValue == staticResult.rawValue)
    }

    // MARK: Functor composition

    @Test
    func `map then retag composition`() {
        let tagged: Tagged<Tag1, Int> = 5
        let result: Tagged<Tag2, String> = tagged.map { String($0) }.retag()
        #expect(result.rawValue == "5")
    }

    @Test
    func `retag then map composition`() {
        let tagged: Tagged<Tag1, Int> = 5
        let result: Tagged<Tag2, String> = tagged.retag(Tag2.self).map { String($0) }
        #expect(result.rawValue == "5")
    }

    @Test
    func `map-retag order does not affect result`() {
        let tagged: Tagged<Tag1, Int> = 5
        let mapFirst: Tagged<Tag2, String> = tagged.map { String($0) }.retag()
        let retagFirst: Tagged<Tag2, String> = tagged.retag(Tag2.self).map { String($0) }
        #expect(mapFirst.rawValue == retagFirst.rawValue)
    }

    // MARK: Tag isolation

    @Test
    func `different tags with same raw value are independent`() {
        var a: Tagged<Tag1, Int> = 42
        let b: Tagged<Tag2, Int> = 42
        a.rawValue = 99
        #expect(a.rawValue == 99)
        #expect(b.rawValue == 42)
    }

    // MARK: Collection interop

    @Test
    func `comparable ordering across multiple values`() {
        let values: [Tagged<Tag1, Int>] = [3, 1, 4, 1, 5, 9, 2, 6]
        let sorted = values.sorted()
        #expect(sorted == [1, 1, 2, 3, 4, 5, 6, 9])
    }

    @Test
    func `hashable in set`() {
        let a: Tagged<Tag1, Int> = 1
        let b: Tagged<Tag1, Int> = 2
        let c: Tagged<Tag1, Int> = 1
        let set: Set<Tagged<Tag1, Int>> = [a, b, c]
        #expect(set.count == 2)
    }

    // MARK: ~Copyable RawValue

    @Test
    func `init and rawValue access with noncopyable raw value`() {
        struct Resource: ~Copyable { let id: Int }
        let tagged = Tagged<Tag1, Resource>(__unchecked: (), Resource(id: 99))
        #expect(tagged.rawValue.id == 99)
    }

    @Test
    func `map with noncopyable raw value`() {
        struct Resource: ~Copyable { let id: Int }
        let tagged = Tagged<Tag1, Resource>(__unchecked: (), Resource(id: 7))
        let mapped: Tagged<Tag1, Int> = tagged.map { $0.id }
        #expect(mapped.rawValue == 7)
    }

    @Test
    func `retag with noncopyable raw value`() {
        struct Resource: ~Copyable { let id: Int }
        let tagged = Tagged<Tag1, Resource>(__unchecked: (), Resource(id: 42))
        let retagged: Tagged<Tag2, Resource> = tagged.retag()
        #expect(retagged.rawValue.id == 42)
    }

    @Test
    func `modify with noncopyable raw value`() {
        struct Resource: ~Copyable { var id: Int }
        var tagged = Tagged<Tag1, Resource>(__unchecked: (), Resource(id: 1))
        tagged.modify { $0.id = 99 }
        #expect(tagged.rawValue.id == 99)
    }

    @Test
    func `MemoryLayout of noncopyable Tagged matches raw value`() {
        struct Resource: ~Copyable { let id: Int; let priority: Int }
        #expect(MemoryLayout<Tagged<Tag1, Resource>>.size == MemoryLayout<Resource>.size)
        #expect(MemoryLayout<Tagged<Tag1, Resource>>.stride == MemoryLayout<Resource>.stride)
        #expect(MemoryLayout<Tagged<Tag1, Resource>>.alignment == MemoryLayout<Resource>.alignment)
    }

    // MARK: Conditional Conformances — Sendable

    @Test
    func `Tagged is Sendable when RawValue is Sendable`() {
        func _requireSendable<T: Sendable>(_: T.Type) {}
        _requireSendable(Tagged<Tag1, Int>.self)
        _requireSendable(Tagged<Tag1, String>.self)
        #expect(Bool(true))
    }

    // MARK: Conditional Conformances — BitwiseCopyable

    @Test
    func `Tagged is BitwiseCopyable when RawValue is BitwiseCopyable`() {
        func _requireBitwiseCopyable<T: BitwiseCopyable>(_: T.Type) {}
        _requireBitwiseCopyable(Tagged<Tag1, Int>.self)
        _requireBitwiseCopyable(Tagged<Tag1, UInt64>.self)
        _requireBitwiseCopyable(Tagged<Tag1, Double>.self)
        _requireBitwiseCopyable(Tagged<Tag1, Bool>.self)
        #expect(Bool(true))
    }

    // MARK: Conditional Conformances — Codable

    @Test
    func `Tagged is Codable when RawValue is Codable`() {
        func _requireCodable<T: Codable>(_: T.Type) {}
        _requireCodable(Tagged<Tag1, Int>.self)
        _requireCodable(Tagged<Tag1, String>.self)
        #expect(Bool(true))
    }

    // MARK: Conditional Conformances — Escapable lattice cell C

    @Test
    func `Tagged is Escapable when RawValue is Escapable & ~Copyable`() {
        // Lattice cell C: RawValue carries Escapable (default) and ~Copyable.
        // The conformance `Tagged: Escapable where RawValue: Escapable & ~Copyable`
        // (Tagged.swift line 69) is asserted at compile time via
        // _requireEscapable; the helper accepts ~Copyable types so the
        // resulting Tagged<Tag, Resource> (which is ~Copyable & Escapable
        // per cell C) is admitted.
        func _requireEscapable<T: Escapable & ~Copyable>(_: T.Type) {}
        struct Resource: ~Copyable { let id: Int }
        _requireEscapable(Tagged<Tag1, Resource>.self)
        #expect(Bool(true))
    }

    // MARK: ~Escapable RawValue support (commit 1cf5396)

    @Test
    func `Tagged admits ~Escapable RawValue in MemoryLayout`() {
        // A ~Copyable & ~Escapable RawValue should produce a Tagged
        // whose layout matches — the phantom Tag contributes nothing.
        struct Scoped: ~Copyable, ~Escapable { let raw: Int }
        #expect(MemoryLayout<Tagged<Tag1, Scoped>>.size == MemoryLayout<Scoped>.size)
        #expect(MemoryLayout<Tagged<Tag1, Scoped>>.stride == MemoryLayout<Scoped>.stride)
        #expect(MemoryLayout<Tagged<Tag1, Scoped>>.alignment == MemoryLayout<Scoped>.alignment)
    }

    // Note: `Tagged: Ownership.Borrow.Protocol` conformance now lives in
    // swift-ownership-primitives (Sources/Ownership Borrow Primitives/
    // Tagged+Ownership.Borrow.Protocol.swift) per the ecosystem pattern
    // where Tagged conformances to non-stdlib capability protocols live
    // with the protocol's home package. The conformance test moved with
    // it.
}

// MARK: - Performance

extension `Tagged Tests`.Performance {

    @Test
    func `retag round-trip identity holds across batched operations`() {
        // Smoke test for the zero-cost retag claim — exercises the hot path
        // in a release-mode-equivalent loop. The codegen experiment
        // (Experiments/tagged-zero-cost-codegen) carries the rigorous
        // proof; this guards against runtime regressions.
        var sum: Int = 0
        for i in 0..<1_000 {
            let tagged: Tagged<Tag1, Int> = .init(__unchecked: (), i)
            let retagged: Tagged<Tag2, Int> = tagged.retag()
            let restored: Tagged<Tag1, Int> = retagged.retag()
            sum &+= restored.rawValue
        }
        #expect(sum == (0..<1_000).reduce(0, &+))
    }
}
