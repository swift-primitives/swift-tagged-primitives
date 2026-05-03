import Testing
import Carrier_Primitives
import Carrier_Primitives_Standard_Library_Integration
@testable import Tagged_Primitives
import Tagged_Primitives_Standard_Library_Integration

// Tagged is generic — parallel namespace pattern per [SWIFT-TEST-003].

private enum Tag1 {}
private enum Tag2 {}
private enum Tag3 {}

// MARK: - Generic dispatch helpers

// A function constrained on `Carrier.`Protocol`<Int>` — accepts any value
// whose immediate Underlying type is Int. Used to verify single-level
// Tagged conformance.
private func describeIntCarrier<C: Carrier.`Protocol`>(_ c: C) -> Int
where C.Underlying == Int {
    c.underlying
}

// A function constrained on bare `Carrier.`Protocol`` (no Underlying
// constraint) — accepts any Carrier. Returns the Underlying type name as
// a string for runtime assertion.
private func describeAnyCarrier<C: Carrier.`Protocol`>(_ c: C) -> String {
    String(describing: C.Underlying.self)
}

// MARK: - Tagged + Carrier

@Suite
struct `Tagged + Carrier Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit

extension `Tagged + Carrier Tests`.Unit {

    // MARK: Domain associated-type discrimination

    @Test
    func `Domain associatedtype equals the phantom Tag`() {
        let _: Tagged<Tag1, Int> = 1
        // Compile-time assertion: Tagged<Tag1, Int>.Domain == Tag1.
        let _: Tagged<Tag1, Int>.Domain.Type = Tag1.self
    }

    @Test
    func `different phantom Tags retain distinct Domain`() {
        let _: Tagged<Tag1, Int> = 1
        let _: Tagged<Tag2, Int> = 1
        // Compile-time assertions: distinct Domain types.
        let _: Tagged<Tag1, Int>.Domain.Type = Tag1.self
        let _: Tagged<Tag2, Int>.Domain.Type = Tag2.self
    }

    // MARK: Immediate-Underlying typealias

    @Test
    func `Underlying associatedtype equals the immediate generic parameter`() {
        // Compile-time assertion: Tagged<Tag1, Int>.Underlying == Int.
        let _: Tagged<Tag1, Int>.Underlying.Type = Int.self
    }

    @Test
    func `nested Tagged exposes immediate wrapped type as Underlying`() {
        // Compile-time assertion: Tagged<Tag1, Tagged<Tag2, Int>>.Underlying
        // == Tagged<Tag2, Int> (the IMMEDIATE wrapped type, not the cascade-end Int).
        let _: Tagged<Tag1, Tagged<Tag2, Int>>.Underlying.Type
            = Tagged<Tag2, Int>.self
    }
}

// MARK: - Edge Case

extension `Tagged + Carrier Tests`.`Edge Case` {

    // MARK: Manual recursion across nested Tagged

    @Test
    func `triple-nested Tagged reaches innermost via explicit recursion`() {
        // The immediate-Underlying design hands the consumer one layer at a
        // time. To reach the bottom, the consumer recurses explicitly:
        //   outer.underlying → middle (Tagged<Tag2, Tagged<Tag3, Int>>)
        //   middle.underlying → inner (Tagged<Tag3, Int>)
        //   inner.underlying  → Int
        //
        // Construction goes through ExpressibleByIntegerLiteral, which
        // recurses through each Tagged layer's literal init independently
        // of the Carrier conformance.
        let outer: Tagged<Tag1, Tagged<Tag2, Tagged<Tag3, Int>>> = 99
        let middle = outer.underlying    // Tagged<Tag2, Tagged<Tag3, Int>>
        let inner  = middle.underlying   // Tagged<Tag3, Int>
        let value  = inner.underlying    // Int
        #expect(value == 99)
    }

    @Test
    func `triple-nested Tagged construction uses literal at each layer`() {
        // No Carrier-cascade init exists; construction relies on
        // ExpressibleByIntegerLiteral cascading through each layer.
        let constructed: Tagged<Tag1, Tagged<Tag2, Tagged<Tag3, Int>>> = 7
        #expect(constructed.underlying.underlying.underlying == 7)
    }
}

// MARK: - Integration

extension `Tagged + Carrier Tests`.Integration {

    // MARK: Single-level Tagged

    @Test
    func `single-level Tagged conforms to Carrier with Underlying == Int`() {
        let tagged: Tagged<Tag1, Int> = 42
        let underlying = describeIntCarrier(tagged)
        #expect(underlying == 42)
    }

    @Test
    func `single-level Tagged round-trips through Carrier init`() {
        let constructed: Tagged<Tag1, Int> = .init(99)
        #expect(constructed.underlying == 99)
    }

    // MARK: Form-D generic algorithm — accepts any Carrier

    @Test
    func `Form-D generic algorithm reports immediate Underlying type`() {
        let bare: Int = 1
        let single: Tagged<Tag1, Int> = 2

        // bare Int's Underlying is Int (trivial-self carrier).
        #expect(describeAnyCarrier(bare) == "Int")
        // Tagged<Tag1, Int>'s immediate Underlying is Int.
        #expect(describeAnyCarrier(single) == "Int")
    }

    @Test
    func `Form-D generic algorithm distinguishes nesting layers`() {
        let nested: Tagged<Tag1, Tagged<Tag2, Int>> = 3

        // The immediate Underlying is Tagged<Tag2, Int>, NOT Int.
        // This is the deliberate trade-off vs the prior cascade design:
        // nested Tagged is honest about its structure; consumers that
        // need the bottom-most type recurse explicitly.
        let typeName = describeAnyCarrier(nested)
        #expect(typeName.contains("Tagged"))
        #expect(typeName.contains("Tag2"))
    }
}

// MARK: - Performance

extension `Tagged + Carrier Tests`.Performance {

    @Test
    func `Form-D dispatch holds across batched carriers`() {
        // Hot-path smoke check for the Carrier conformance — generic dispatch
        // through `describeIntCarrier` must compile to a direct underlying-
        // value access (no boxing, no virtual dispatch).
        var sum: Int = 0
        for i in 0..<1_000 {
            let tagged = Tagged<Tag1, Int>(_unchecked: i)
            sum &+= describeIntCarrier(tagged)
        }
        #expect(sum == (0..<1_000).reduce(0, &+))
    }
}
