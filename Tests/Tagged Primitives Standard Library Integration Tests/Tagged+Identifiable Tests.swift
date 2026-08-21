import Tagged_Primitives_Standard_Library_Integration
import Testing

@testable import Tagged_Primitives

private enum Tag1 {}
private enum Tag2 {}

private struct DomainKey: Identifiable, Hashable, Equatable, Sendable {
    let id: UInt64
}

@Suite
struct `Tagged + Identifiable Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `Tagged + Identifiable Tests`.Unit {

    @Test
    func `id forwards to Underlying id`() {
        let key = DomainKey(id: 42)
        let tagged: Tagged<Tag1, DomainKey> = Tagged<Tag1, DomainKey>(_unchecked: key)
        #expect(tagged.id == 42)
    }

    @Test
    func `Tagged conforms to Identifiable when Underlying conforms`() {
        func _requireIdentifiable<T: Identifiable>(_: T.Type) {}
        _requireIdentifiable(Tagged<Tag1, DomainKey>.self)
        #expect(Bool(true))
    }

    @Test
    func `id type matches Underlying ID type`() {
        let key = DomainKey(id: 7)
        let tagged: Tagged<Tag1, DomainKey> = Tagged<Tag1, DomainKey>(_unchecked: key)
        let _: UInt64 = tagged.id
    }
}

extension `Tagged + Identifiable Tests`.`Edge Case` {

    @Test
    func `phantom-Tag-distinct values with same Underlying id observe identity-inversion`() {

        let key = DomainKey(id: 99)
        let a: Tagged<Tag1, DomainKey> = Tagged<Tag1, DomainKey>(_unchecked: key)
        let b: Tagged<Tag2, DomainKey> = Tagged<Tag2, DomainKey>(_unchecked: key)
        #expect(a.id == b.id)
    }
}

extension `Tagged + Identifiable Tests`.Integration {

    @Test
    func `generic Identifiable algorithm sees the underlying id`() {
        func describe<T: Identifiable>(_ value: T) -> String where T.ID == UInt64 {
            "id=\(value.id)"
        }
        let key = DomainKey(id: 314)
        let tagged: Tagged<Tag1, DomainKey> = Tagged<Tag1, DomainKey>(_unchecked: key)
        #expect(describe(tagged) == "id=314")
    }
}

extension `Tagged + Identifiable Tests`.Performance {

    @Test
    func `id access batched`() {
        var sum: UInt64 = 0
        (0..<UInt64(1_000)).forEach { i in
            let tagged: Tagged<Tag1, DomainKey> = Tagged<Tag1, DomainKey>(
                _unchecked: DomainKey(id: i)
            )
            sum &+= tagged.id
        }
        #expect(sum == (0..<1_000).reduce(0, &+))
    }
}
