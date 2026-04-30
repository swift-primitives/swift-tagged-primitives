import Testing
@testable import Tagged_Primitives
import Tagged_Primitives_Standard_Library_Integration

private enum Tag1 {}

@Suite
struct `Tagged + Literals Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit

extension `Tagged + Literals Tests`.Unit {

    @Test
    func `integer literal constructs Tagged from Int`() {
        let tagged: Tagged<Tag1, Int> = 42
        #expect(tagged.rawValue == 42)
    }

    @Test
    func `float literal constructs Tagged from Double`() {
        let tagged: Tagged<Tag1, Double> = 3.14
        #expect(tagged.rawValue == 3.14)
    }

    @Test
    func `boolean literal constructs Tagged from Bool`() {
        let taggedTrue: Tagged<Tag1, Bool> = true
        let taggedFalse: Tagged<Tag1, Bool> = false
        #expect(taggedTrue.rawValue == true)
        #expect(taggedFalse.rawValue == false)
    }

    @Test
    func `string literal constructs Tagged from String`() {
        let tagged: Tagged<Tag1, String> = "hello"
        #expect(tagged.rawValue == "hello")
    }

    @Test
    func `unicode-scalar literal constructs Tagged from Character`() {
        let tagged: Tagged<Tag1, Character> = "A"
        #expect(tagged.rawValue == "A")
    }

    @Test
    func `array literal constructs Tagged from Array via RangeReplaceableCollection path`() {
        let tagged: Tagged<Tag1, [Int]> = [10, 20, 30]
        #expect(tagged.rawValue == [10, 20, 30])
    }

    @Test
    func `array literal constructs Tagged from ContiguousArray via RRC path`() {
        let tagged: Tagged<Tag1, ContiguousArray<Int>> = [1, 2, 3]
        #expect(Array(tagged.rawValue) == [1, 2, 3])
    }

    @Test
    func `array literal constructs Tagged from Set via parametric ExpressibleByArrayLiteral`() {
        let tagged: Tagged<Tag1, Set<Int>> = [1, 2, 3]
        #expect(tagged.rawValue == Set([1, 2, 3]))
    }

    @Test
    func `dictionary literal constructs Tagged from Dictionary`() {
        let tagged: Tagged<Tag1, [String: Int]> = ["alice": 1, "bob": 2]
        #expect(tagged.rawValue == ["alice": 1, "bob": 2])
    }
}

// MARK: - Edge Case

extension `Tagged + Literals Tests`.`Edge Case` {

    @Test
    func `boundary integer literals work`() {
        let zero: Tagged<Tag1, Int> = 0
        let negOne: Tagged<Tag1, Int> = -1
        let posOne: Tagged<Tag1, Int> = 1
        #expect(zero.rawValue == 0)
        #expect(negOne.rawValue == -1)
        #expect(posOne.rawValue == 1)
    }

    @Test
    func `empty string literal works`() {
        let tagged: Tagged<Tag1, String> = ""
        #expect(tagged.rawValue.isEmpty)
    }

    @Test
    func `string interpolation literal constructs correctly`() {
        let n = 42
        let tagged: Tagged<Tag1, String> = "value=\(n)"
        #expect(tagged.rawValue == "value=42")
    }
}

// MARK: - Integration

extension `Tagged + Literals Tests`.Integration {

    @Test
    func `phantom Tags remain distinct under literal init`() {
        enum OtherTag {}
        let a: Tagged<Tag1, Int> = 42
        let b: Tagged<OtherTag, Int> = 42
        #expect(type(of: a) != type(of: b))
        // a == b would not compile — different types preserved by phantom Tag.
    }

    @Test
    func `literal init produces same value as canonical init`() {
        let viaLiteral: Tagged<Tag1, Int> = 99
        let viaCanonical = Tagged<Tag1, Int>(__unchecked: (), 99)
        #expect(viaLiteral == viaCanonical)
    }
}

// MARK: - Performance

extension `Tagged + Literals Tests`.Performance {

    @Test
    func `literal construction batched`() {
        var sum = 0
        for _ in 0..<1_000 {
            let tagged: Tagged<Tag1, Int> = 1
            sum &+= tagged.rawValue
        }
        #expect(sum == 1_000)
    }
}
