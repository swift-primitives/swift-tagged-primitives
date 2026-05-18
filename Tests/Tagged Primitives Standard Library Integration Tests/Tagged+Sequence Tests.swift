import Tagged_Primitives_Standard_Library_Integration
import Tagged_Primitives_Test_Support
import Testing

@testable import Tagged_Primitives

private enum Tag1 {}

@Suite
struct `Tagged + Sequence Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit

extension `Tagged + Sequence Tests`.Unit {

    @Test
    func `makeIterator forwards to Underlying`() {
        let tagged: Tagged<Tag1, [Int]> = [1, 2, 3]
        var iter = tagged.makeIterator()
        #expect(iter.next() == 1)
        #expect(iter.next() == 2)
        #expect(iter.next() == 3)
        #expect(iter.next() == nil)
    }

    @Test
    func `Tagged conforms to Sequence when Underlying conforms`() {
        func _requireSequence<T: Swift.Sequence>(_: T.Type) {}
        _requireSequence(Tagged<Tag1, [Int]>.self)
        _requireSequence(Tagged<Tag1, Set<Int>>.self)
        #expect(Bool(true))
    }
}

// MARK: - Edge Case

extension `Tagged + Sequence Tests`.`Edge Case` {

    @Test
    func `empty sequence iterates zero times`() {
        let tagged: Tagged<Tag1, [Int]> = []
        var count = 0
        for _ in tagged { count += 1 }
        #expect(count == 0)
    }

    @Test
    func `for-in produces same elements as underlying iteration`() {
        let tagged: Tagged<Tag1, [Int]> = [10, 20, 30]
        var viaTagged: [Int] = []
        for x in tagged { viaTagged.append(x) }
        var viaRaw: [Int] = []
        for x in tagged.underlying { viaRaw.append(x) }
        #expect(viaTagged == viaRaw)
    }
}

// MARK: - Integration

extension `Tagged + Sequence Tests`.Integration {

    @Test
    func `generic Sequence algorithm accepts Tagged`() {
        // The cost the rationale critiques: a generic T: Sequence algorithm
        // treats Tagged<Tag, [Int]> identically to [Int].
        func sum<S: Swift.Sequence>(_ s: S) -> Int where S.Element == Int {
            s.reduce(0, +)
        }
        let tagged: Tagged<Tag1, [Int]> = [1, 2, 3, 4]
        let plain: [Int] = [1, 2, 3, 4]
        #expect(sum(tagged) == sum(plain))
        #expect(sum(tagged) == 10)
    }
}

// MARK: - Performance

extension `Tagged + Sequence Tests`.Performance {

    @Test
    func `iteration batched`() {
        let elements = Array(0..<1_000)
        let tagged: Tagged<Tag1, [Int]> = Tagged<Tag1, [Int]>(_unchecked: elements)
        var sum = 0
        for x in tagged { sum &+= x }
        #expect(sum == elements.reduce(0, &+))
    }
}
