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
// whose Underlying type chain resolves to Int. Used to verify the cascade.
private func describeIntCarrier<C: Carrier.`Protocol`>(_ c: C) -> Int
where C.Underlying == Int {
    c.underlying
}

// A function constrained on bare `Carrier.`Protocol`` (no Underlying
// constraint) — accepts any Carrier. Used to verify Form-D generic
// algorithms. Returns the Underlying type name as a string for runtime
// assertion.
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
}

// MARK: - Edge Case

extension `Tagged + Carrier Tests`.`Edge Case` {

    // MARK: Deep nesting — three-level cascade

    @Test
    func `triple-nested Tagged cascades through to innermost Underlying`() {
        // Three-level wrapping: Tagged<X, Tagged<Y, Tagged<Z, Int>>>.
        // Cascading literal init via ExpressibleByIntegerLiteral works
        // recursively because each Tagged layer conforms when its Underlying
        // does — Int → Tagged<Tag3, Int> → Tagged<Tag2, Tagged<Tag3, Int>>
        // → Tagged<Tag1, Tagged<Tag2, Tagged<Tag3, Int>>>.
        let outer: Tagged<Tag1, Tagged<Tag2, Tagged<Tag3, Int>>> = 99
        let underlying = describeIntCarrier(outer)
        #expect(underlying == 99)
    }

    @Test
    func `triple-nested Tagged init reconstructs the chain from raw underlying`() {
        // The Carrier init transfers ownership end-to-end across all levels.
        let constructed: Tagged<Tag1, Tagged<Tag2, Tagged<Tag3, Int>>> = .init(7)
        #expect(constructed.underlying == 7)
        #expect(constructed.underlying.underlying.underlying == 7)
    }
}

// MARK: - Integration

extension `Tagged + Carrier Tests`.Integration {

    // MARK: One-level cascade — Tagged<Tag, Int>

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
        #expect(constructed.underlying == 99)
    }

    // MARK: Two-level cascade — Tagged<Tag, Tagged<OtherTag, Int>>

    @Test
    func `nested Tagged conforms to Carrier with Underlying cascading to Int`() {
        let outer: Tagged<Tag1, Tagged<Tag2, Int>> = 7
        let underlying = describeIntCarrier(outer)
        #expect(underlying == 7)
    }

    @Test
    func `nested Tagged init reconstructs the chain from raw underlying`() {
        let constructed: Tagged<Tag1, Tagged<Tag2, Int>> = .init(13)
        #expect(constructed.underlying == 13)
        #expect(constructed.underlying.underlying == 13)
    }

    // MARK: Form-D generic algorithm — accepts any Carrier

    @Test
    func `Form-D generic algorithm accepts bare and Tagged uniformly`() {
        let bare: Int = 1
        let single: Tagged<Tag1, Int> = 2
        let nested: Tagged<Tag1, Tagged<Tag2, Int>> = 3

        // All three resolve to the same Underlying type — Int.
        #expect(describeAnyCarrier(bare) == "Int")
        #expect(describeAnyCarrier(single) == "Int")
        #expect(describeAnyCarrier(nested) == "Int")
    }
}

// MARK: - Performance

extension `Tagged + Carrier Tests`.Performance {

    @Test
    func `Form-D dispatch holds across batched carriers`() {
        // Hot-path smoke check for the cascading Carrier conformance — the
        // generic dispatch through `describeIntCarrier` must compile to
        // a direct underlying-value access (no boxing, no virtual dispatch).
        var sum: Int = 0
        for i in 0..<1_000 {
            let tagged = Tagged<Tag1, Int>(_unchecked: i)
            sum &+= describeIntCarrier(tagged)
        }
        #expect(sum == (0..<1_000).reduce(0, &+))
    }
}
