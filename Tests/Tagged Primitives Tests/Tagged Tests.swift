import Testing
import Carrier_Primitives
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
    func `init stores underlying value`() {
        let tagged: Tagged<Tag1, Int> = 42
        #expect(tagged.underlying == 42)
    }

    @Test
    func `integer literal construction`() {
        let tagged: Tagged<Tag1, Int> = 99
        #expect(tagged.underlying == 99)
    }

    @Test
    func `string literal construction`() {
        let tagged: Tagged<Tag1, String> = "hello"
        #expect(tagged.underlying == "hello")
    }

    @Test
    func `boolean literal construction`() {
        let tagged: Tagged<Tag1, Bool> = true
        #expect(tagged.underlying == true)
    }

    @Test
    func `float literal construction`() {
        let tagged: Tagged<Tag1, Double> = 3.14
        #expect(tagged.underlying == 3.14)
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

    // MARK: underlying

    @Test
    func `underlying read returns stored value`() {
        let tagged: Tagged<Tag1, Int> = 7
        #expect(tagged.underlying == 7)
    }

    @Test
    func `modify mutates underlying in place`() {
        var tagged: Tagged<Tag1, Int> = 10
        tagged.modify { $0 += 5 }
        #expect(tagged.underlying == 15)
    }

    // MARK: modify (package-internal)

    @Test
    func `modify mutates underlying value via closure`() {
        var tagged: Tagged<Tag1, Int> = 10
        let result = tagged.modify { value in
            value *= 3
            return value
        }
        #expect(result == 30)
        #expect(tagged.underlying == 30)
    }

    // MARK: Equatable

    @Test
    func `equal underlying values are equal`() {
        let a: Tagged<Tag1, Int> = 42
        let b: Tagged<Tag1, Int> = 42
        #expect(a == b)
    }

    @Test
    func `different underlying values are not equal`() {
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
    func `less than compares underlying values`() {
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
    func `instance map transforms underlying value preserving tag`() {
        let tagged: Tagged<Tag1, Int> = 5
        let result = tagged.map { $0 * 2 }
        #expect(result == 10)
    }

    @Test
    func `static map transforms underlying value preserving tag`() {
        let tagged: Tagged<Tag1, Int> = 5
        let result = Tagged<Tag1, Int>.map(tagged) { $0 * 2 }
        #expect(result == 10)
    }

    @Test
    func `map changes underlying value type`() {
        let tagged: Tagged<Tag1, Int> = 42
        let result: Tagged<Tag1, String> = tagged.map { String($0) }
        #expect(result.underlying == "42")
    }

    // MARK: retag

    @Test
    func `instance retag changes tag preserving underlying value`() {
        let tagged: Tagged<Tag1, Int> = 42
        let retagged: Tagged<Tag2, Int> = tagged.retag()
        #expect(retagged.underlying == 42)
    }

    @Test
    func `static retag changes tag preserving underlying value`() {
        let tagged: Tagged<Tag1, Int> = 42
        let retagged = Tagged<Tag1, Int>.retag(tagged, to: Tag2.self)
        #expect(retagged.underlying == 42)
    }

    // MARK: CustomStringConvertible

    @Test
    func `description forwards to underlying value`() {
        let tagged: Tagged<Tag1, Int> = 42
        #expect(tagged.description == "42")
    }

    @Test
    func `string description forwards to underlying value`() {
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
        #expect(c.underlying == direct.underlying)
    }

    // MARK: Boundary underlying values

    @Test
    func `zero underlying value`() {
        let tagged: Tagged<Tag1, Int> = 0
        #expect(tagged.underlying == 0)
        #expect(tagged == 0)
    }

    @Test
    func `negative underlying value`() {
        let tagged: Tagged<Tag1, Int> = -42
        #expect(tagged.underlying == -42)
    }

    @Test
    func `empty string underlying value`() {
        let tagged: Tagged<Tag1, String> = ""
        #expect(tagged.underlying.isEmpty)
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
        #expect(instanceResult.underlying == staticResult.underlying)
    }

    // MARK: Functor composition

    @Test
    func `map then retag composition`() {
        let tagged: Tagged<Tag1, Int> = 5
        let result: Tagged<Tag2, String> = tagged.map { String($0) }.retag()
        #expect(result.underlying == "5")
    }

    @Test
    func `retag then map composition`() {
        let tagged: Tagged<Tag1, Int> = 5
        let result: Tagged<Tag2, String> = tagged.retag(Tag2.self).map { String($0) }
        #expect(result.underlying == "5")
    }

    @Test
    func `map-retag order does not affect result`() {
        let tagged: Tagged<Tag1, Int> = 5
        let mapFirst: Tagged<Tag2, String> = tagged.map { String($0) }.retag()
        let retagFirst: Tagged<Tag2, String> = tagged.retag(Tag2.self).map { String($0) }
        #expect(mapFirst.underlying == retagFirst.underlying)
    }

    // MARK: Tag isolation

    @Test
    func `different tags with same underlying are independent`() {
        var a: Tagged<Tag1, Int> = 42
        let b: Tagged<Tag2, Int> = 42
        a.modify { $0 = 99 }
        #expect(a.underlying == 99)
        #expect(b.underlying == 42)
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

    // MARK: ~Copyable Underlying

    @Test
    func `init and underlying access with noncopyable underlying value`() {
        struct Resource: ~Copyable, Carrier.`Protocol` { let id: Int; typealias Underlying = Self }
        let tagged = Tagged<Tag1, Resource>(_unchecked: Resource(id: 99))
        #expect(tagged.underlying.id == 99)
    }

    @Test
    func `map with noncopyable underlying value`() {
        struct Resource: ~Copyable, Carrier.`Protocol` { let id: Int; typealias Underlying = Self }
        let tagged = Tagged<Tag1, Resource>(_unchecked: Resource(id: 7))
        let mapped: Tagged<Tag1, Int> = tagged.map { $0.id }
        #expect(mapped.underlying == 7)
    }

    @Test
    func `retag with noncopyable underlying value`() {
        struct Resource: ~Copyable, Carrier.`Protocol` { let id: Int; typealias Underlying = Self }
        let tagged = Tagged<Tag1, Resource>(_unchecked: Resource(id: 42))
        let retagged: Tagged<Tag2, Resource> = tagged.retag()
        #expect(retagged.underlying.id == 42)
    }

    @Test
    func `modify with noncopyable underlying value`() {
        struct Resource: ~Copyable, Carrier.`Protocol` { var id: Int; typealias Underlying = Self }
        var tagged = Tagged<Tag1, Resource>(_unchecked: Resource(id: 1))
        tagged.modify { $0.id = 99 }
        #expect(tagged.underlying.id == 99)
    }

    @Test
    func `MemoryLayout of noncopyable Tagged matches underlying value`() {
        struct Resource: ~Copyable { let id: Int; let priority: Int }
        #expect(MemoryLayout<Tagged<Tag1, Resource>>.size == MemoryLayout<Resource>.size)
        #expect(MemoryLayout<Tagged<Tag1, Resource>>.stride == MemoryLayout<Resource>.stride)
        #expect(MemoryLayout<Tagged<Tag1, Resource>>.alignment == MemoryLayout<Resource>.alignment)
    }

    @Test
    func `consume-extract noncopyable underlying out of consumed Tagged`() {
        // Regression test: pre-rename `public var rawValue` was a stored
        // property allowing consume-extract on a consumed `tagged`. The
        // 96f2a76 rename converted to a `_read` accessor and lost this
        // capability. The fix restored a stored `public package(set) var
        // underlying` (this experiment + main commit).
        struct Resource: ~Copyable, Carrier.`Protocol` {
            let id: Int
            typealias Underlying = Self
        }
        func extract(_ t: consuming Tagged<Tag1, Resource>) -> Resource {
            t.underlying  // direct stored field on consumed host: partial-consume
        }
        let tagged = Tagged<Tag1, Resource>(_unchecked: Resource(id: 7))
        let extracted = extract(tagged)
        #expect(extracted.id == 7)
    }

    // MARK: Conditional Conformances — Sendable

    @Test
    func `Tagged is Sendable when Underlying is Sendable`() {
        func _requireSendable<T: Sendable>(_: T.Type) {}
        _requireSendable(Tagged<Tag1, Int>.self)
        _requireSendable(Tagged<Tag1, String>.self)
        #expect(Bool(true))
    }

    // MARK: Conditional Conformances — BitwiseCopyable

    @Test
    func `Tagged is BitwiseCopyable when Underlying is BitwiseCopyable`() {
        func _requireBitwiseCopyable<T: BitwiseCopyable>(_: T.Type) {}
        _requireBitwiseCopyable(Tagged<Tag1, Int>.self)
        _requireBitwiseCopyable(Tagged<Tag1, UInt64>.self)
        _requireBitwiseCopyable(Tagged<Tag1, Double>.self)
        _requireBitwiseCopyable(Tagged<Tag1, Bool>.self)
        #expect(Bool(true))
    }

    // MARK: Conditional Conformances — Codable

    @Test
    func `Tagged is Codable when Underlying is Codable`() {
        func _requireCodable<T: Codable>(_: T.Type) {}
        _requireCodable(Tagged<Tag1, Int>.self)
        _requireCodable(Tagged<Tag1, String>.self)
        #expect(Bool(true))
    }

    // MARK: Conditional Conformances — Escapable lattice cell C

    @Test
    func `Tagged is Escapable when Underlying is Escapable & ~Copyable`() {
        // Lattice cell C: Underlying carries Escapable (default) and ~Copyable.
        // The conformance `Tagged: Escapable where Underlying: Escapable & ~Copyable`
        // (Tagged.swift line 69) is asserted at compile time via
        // _requireEscapable; the helper accepts ~Copyable types so the
        // resulting Tagged<Tag, Resource> (which is ~Copyable & Escapable
        // per cell C) is admitted.
        func _requireEscapable<T: Escapable & ~Copyable>(_: T.Type) {}
        struct Resource: ~Copyable, Carrier.`Protocol` { let id: Int; typealias Underlying = Self }
        _requireEscapable(Tagged<Tag1, Resource>.self)
        #expect(Bool(true))
    }

    // MARK: ~Escapable Underlying support (commit 1cf5396)

    @Test
    func `Tagged admits ~Escapable Underlying in MemoryLayout`() {
        // A ~Copyable & ~Escapable Underlying should produce a Tagged
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
            let tagged: Tagged<Tag1, Int> = .init(_unchecked: i)
            let retagged: Tagged<Tag2, Int> = tagged.retag()
            let restored: Tagged<Tag1, Int> = retagged.retag()
            sum &+= restored.underlying
        }
        #expect(sum == (0..<1_000).reduce(0, &+))
    }
}
