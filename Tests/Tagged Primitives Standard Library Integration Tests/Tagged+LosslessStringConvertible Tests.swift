import Testing
@testable import Tagged_Primitives
import Tagged_Primitives_Standard_Library_Integration

private enum Tag1 {}
private enum Tag2 {}

@Suite
struct `Tagged + LosslessStringConvertible Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit

extension `Tagged + LosslessStringConvertible Tests`.Unit {

    @Test
    func `init parses valid string`() {
        let tagged: Tagged<Tag1, Int>? = Tagged<Tag1, Int>(String("42"))
        #expect(tagged?.rawValue == 42)
    }

    @Test
    func `init returns nil for invalid string`() {
        let tagged: Tagged<Tag1, Int>? = Tagged<Tag1, Int>(String("not-an-int"))
        #expect(tagged == nil)
    }

    @Test
    func `description forwards to rawValue description`() {
        let tagged: Tagged<Tag1, Int> = 99
        #expect(tagged.description == "99")
    }

    @Test
    func `Tagged conforms to LosslessStringConvertible when RawValue conforms`() {
        func _requireLossless<T: LosslessStringConvertible>(_: T.Type) {}
        _requireLossless(Tagged<Tag1, Int>.self)
        #expect(Bool(true))
    }
}

// MARK: - Edge Case

extension `Tagged + LosslessStringConvertible Tests`.`Edge Case` {

    @Test
    func `within-domain roundtrip preserves value`() {
        let original: Tagged<Tag1, Int> = 100
        let serialized = original.description
        let reconstructed: Tagged<Tag1, Int>? = Tagged<Tag1, Int>(serialized)
        #expect(reconstructed == original)
    }

    @Test
    func `string description does not encode the phantom Tag`() {
        // The cost of the SLI conformance: descriptions are RawValue-only.
        let userVal: Tagged<Tag1, Int> = 42
        let orderVal: Tagged<Tag2, Int> = 42
        #expect(userVal.description == orderVal.description)
    }

    @Test
    func `same string parses to either Tag — receiver type decides`() {
        let asTag1: Tagged<Tag1, Int>? = Tagged<Tag1, Int>(String("99"))
        let asTag2: Tagged<Tag2, Int>? = Tagged<Tag2, Int>(String("99"))
        #expect(asTag1?.rawValue == 99 && asTag2?.rawValue == 99)
    }
}

// MARK: - Integration

extension `Tagged + LosslessStringConvertible Tests`.Integration {

    @Test
    func `roundtrip across many values`() {
        for raw in [Int.min, -1, 0, 1, 42, Int.max] {
            let original: Tagged<Tag1, Int> = Tagged<Tag1, Int>(__unchecked: (), raw)
            let reconstructed: Tagged<Tag1, Int>? = Tagged<Tag1, Int>(original.description)
            #expect(reconstructed == original)
        }
    }
}

// MARK: - Performance

extension `Tagged + LosslessStringConvertible Tests`.Performance {

    @Test
    func `roundtrip batched`() {
        var ok = 0
        for i in 0..<1_000 {
            let original: Tagged<Tag1, Int> = Tagged<Tag1, Int>(__unchecked: (), i)
            if let reconstructed: Tagged<Tag1, Int> = Tagged<Tag1, Int>(original.description),
               reconstructed == original { ok += 1 }
        }
        #expect(ok == 1_000)
    }
}
