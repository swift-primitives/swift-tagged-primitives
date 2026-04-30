import Testing
@testable import Tagged_Primitives
import Tagged_Primitives_Standard_Library_Integration

private enum Tag1 {}

@Suite
struct `Tagged + Collection Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit

extension `Tagged + Collection Tests`.Unit {

    @Test
    func `startIndex and endIndex forward to RawValue`() {
        let tagged: Tagged<Tag1, [Int]> = [10, 20, 30]
        #expect(tagged.startIndex == 0)
        #expect(tagged.endIndex == 3)
    }

    @Test
    func `subscript forwards to RawValue`() {
        let tagged: Tagged<Tag1, [Int]> = [10, 20, 30]
        #expect(tagged[0] == 10)
        #expect(tagged[1] == 20)
        #expect(tagged[2] == 30)
    }

    @Test
    func `index after forwards to RawValue`() {
        let tagged: Tagged<Tag1, [Int]> = [10, 20]
        #expect(tagged.index(after: 0) == 1)
        #expect(tagged.index(after: 1) == 2)
    }

    @Test
    func `Tagged conforms to Collection when RawValue conforms`() {
        func _requireCollection<T: Collection>(_: T.Type) {}
        _requireCollection(Tagged<Tag1, [Int]>.self)
        _requireCollection(Tagged<Tag1, String>.self)
        #expect(Bool(true))
    }
}

// MARK: - Edge Case

extension `Tagged + Collection Tests`.`Edge Case` {

    @Test
    func `empty collection is empty`() {
        let tagged: Tagged<Tag1, [Int]> = []
        #expect(tagged.isEmpty)
        #expect(tagged.first == nil)
    }

    @Test
    func `single element collection`() {
        let tagged: Tagged<Tag1, [Int]> = [42]
        #expect(tagged.count == 1)
        #expect(tagged.first == 42)
    }
}

// MARK: - Integration

extension `Tagged + Collection Tests`.Integration {

    @Test
    func `Collection algorithms work via opt-in conformance`() {
        let tagged: Tagged<Tag1, [Int]> = [3, 1, 4, 1, 5, 9, 2, 6]
        #expect(tagged.count == 8)
        #expect(tagged.first == 3)
        #expect(tagged.contains(4))
        #expect(!tagged.contains(99))
        // .last would require BidirectionalCollection — out of scope for the
        // base Collection conformance the SLI ships.
    }
}

// MARK: - Performance

extension `Tagged + Collection Tests`.Performance {

    @Test
    func `subscript access batched`() {
        let elements = Array(0..<1_000)
        let tagged: Tagged<Tag1, [Int]> = Tagged<Tag1, [Int]>(__unchecked: (), elements)
        var sum = 0
        for i in 0..<tagged.count {
            sum &+= tagged[i]
        }
        #expect(sum == elements.reduce(0, &+))
    }
}
