import Testing

@testable import Tagged_Primitives

// Wire-form checks for `Tagged: Codable`. `Tagged` must encode/decode as the
// BARE underlying value (a single value), NOT as a keyed `{"underlying": …}`
// object — otherwise every consumer that round-trips a domain id through JSON
// breaks. The exact shape is asserted against a rendered JSON string produced
// by a minimal, stdlib-only tree codec (defined at the bottom of this file), so
// the primitive's test surface stays Foundation-free per [PRIM-FOUND-001] — no
// `JSONEncoder`. The codec models a `Tagged<Customer, String>("cus_123")` and
// asserts it renders as `"cus_123"`, never `{"underlying":"cus_123"}`.

// Tagged is generic — parallel namespace pattern per [SWIFT-TEST-003].

private enum Customer {}

// A struct mirroring real API usage: a domain id typed via `Tagged`, alongside
// a plain scalar field. Its `Codable` is compiler-synthesized, so it exercises
// `Tagged` nested inside a keyed container.
private struct Account: Codable, Equatable {
    let id: Tagged<Customer, String>
    let name: String
}

// MARK: - Tagged + Codable

@Suite
struct `Tagged + Codable Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit

extension `Tagged + Codable Tests`.Unit {

    // MARK: (a) exact wire shape — bare value, no object wrapper

    @Test
    func `encodes as the bare underlying value, not a keyed object`() throws {
        let tagged = Tagged<Customer, String>(_unchecked: "cus_123")
        let node = try encodeToNode(tagged)

        // Structural: a single string, not an object.
        #expect(node == .string("cus_123"))

        // Exact JSON shape: the bare string, never `{"underlying":"cus_123"}`.
        let json = renderJSON(node)
        #expect(json == "\"cus_123\"")
        #expect(!json.contains("underlying"))
    }

    // MARK: (b) decode from a bare value

    @Test
    func `decodes from a bare underlying value`() throws {
        let decoded = try decodeFromNode(Tagged<Customer, String>.self, .string("cus_123"))
        #expect(decoded.underlying == "cus_123")
    }

    // MARK: (c) round-trip

    @Test
    func `round-trips through encode then decode`() throws {
        let original = Tagged<Customer, String>(_unchecked: "cus_123")
        let restored = try decodeFromNode(Tagged<Customer, String>.self, try encodeToNode(original))
        #expect(restored == original)
    }
}

// MARK: - Edge Case

extension `Tagged + Codable Tests`.`Edge Case` {

    @Test
    func `empty-string underlying still encodes as a bare value`() throws {
        let tagged = Tagged<Customer, String>(_unchecked: "")
        let node = try encodeToNode(tagged)
        #expect(node == .string(""))
        #expect(renderJSON(node) == "\"\"")
    }

    @Test
    func `underlying with quote and backslash stays a bare escaped value`() throws {
        let tagged = Tagged<Customer, String>(_unchecked: #"a"b\c"#)
        let node = try encodeToNode(tagged)
        #expect(node == .string(#"a"b\c"#))
        // Escaped, still a bare string — not a keyed object.
        #expect(renderJSON(node) == #""a\"b\\c""#)
        #expect(!renderJSON(node).contains("underlying"))

        let restored = try decodeFromNode(Tagged<Customer, String>.self, node)
        #expect(restored == tagged)
    }

    @Test
    func `non-string underlying encodes as a bare scalar`() throws {
        // The bare-wire-form property is not string-specific: a numeric
        // underlying serializes as the bare number, never `{"underlying":42}`.
        let tagged = Tagged<Customer, Int>(_unchecked: 42)
        let node = try encodeToNode(tagged)
        #expect(node == .int(42))
        #expect(renderJSON(node) == "42")

        let restored = try decodeFromNode(Tagged<Customer, Int>.self, .int(42))
        #expect(restored == tagged)
    }
}

// MARK: - Integration

extension `Tagged + Codable Tests`.Integration {

    // MARK: (d) nested inside a Codable struct — real API usage

    @Test
    func `nested Tagged field in a struct encodes as a bare value`() throws {
        let account = Account(id: Tagged<Customer, String>(_unchecked: "cus_123"), name: "Acme Corp")
        let json = renderJSON(try encodeToNode(account))

        // The `id` field is the bare string, NOT a nested `{"underlying":…}`.
        #expect(json == "{\"id\":\"cus_123\",\"name\":\"Acme Corp\"}")
        #expect(!json.contains("underlying"))
    }

    @Test
    func `struct with a Tagged field round-trips`() throws {
        let account = Account(id: Tagged<Customer, String>(_unchecked: "cus_789"), name: "Globex")
        let restored = try decodeFromNode(Account.self, try encodeToNode(account))
        #expect(restored == account)
    }
}

// MARK: - Performance

extension `Tagged + Codable Tests`.Performance {

    @Test
    func `encode-decode round-trip holds across batched values`() throws {
        // Smoke check that the single-value wire form is stable in a hot loop —
        // each value must survive encode → node → decode unchanged.
        try (0..<1_000).forEach { i in
            let original = Tagged<Customer, Int>(_unchecked: i)
            let restored = try decodeFromNode(Tagged<Customer, Int>.self, try encodeToNode(original))
            #expect(restored == original)
        }
    }
}

// ============================================================================
// MARK: - Foundation-free single-value / keyed tree codec
// ============================================================================
//
// A minimal, stdlib-only `Encoder`/`Decoder` pair that renders a value into an
// in-memory `JSONNode` tree (and back), plus a compact JSON string renderer.
// It supports single-value and keyed containers — enough to exercise a bare
// `Tagged` and a flat `Codable` struct — and traps on unkeyed / nested / super
// requests, which the synthesized codecs under test never use. No Foundation.

private enum JSONNode: Equatable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case object([Member])
    case array([JSONNode])

    struct Member: Equatable {
        let key: String
        let value: JSONNode
    }
}

private func renderJSON(_ node: JSONNode) -> String {
    switch node {
    case .null: return "null"
    case .bool(let value): return value ? "true" : "false"
    case .int(let value): return String(value)
    case .double(let value): return String(value)
    case .string(let value): return "\"\(escapeJSON(value))\""
    case .object(let members):
        let body = members.map { "\"\(escapeJSON($0.key))\":\(renderJSON($0.value))" }.joined(separator: ",")
        return "{\(body)}"
    case .array(let items):
        return "[\(items.map(renderJSON).joined(separator: ","))]"
    }
}

private func escapeJSON(_ value: String) -> String {
    var out = ""
    for character in value {
        switch character {
        case "\"": out += "\\\""
        case "\\": out += "\\\\"
        default: out.append(character)
        }
    }
    return out
}

private enum CodecError: Error { case shape(String) }

private func encodeToNode<T: Encodable>(_ value: T) throws -> JSONNode {
    let sink = NodeRef()
    try value.encode(to: TreeEncoder(sink: sink))
    return sink.node
}

private func decodeFromNode<T: Decodable>(_ type: T.Type, _ node: JSONNode) throws -> T {
    try T(from: TreeDecoder(node: node))
}

// MARK: Encoder

private final class NodeRef {
    var node: JSONNode = .null
}

private struct TreeEncoder: Encoder {
    let sink: NodeRef
    var codingPath: [any CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] { [:] }

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(TreeKeyedEncodingContainer<Key>(sink: sink, codingPath: codingPath))
    }
    func unkeyedContainer() -> any UnkeyedEncodingContainer {
        fatalError("TreeEncoder: unkeyed containers are unused by these tests")
    }
    func singleValueContainer() -> any SingleValueEncodingContainer {
        TreeSingleValueEncodingContainer(sink: sink, codingPath: codingPath)
    }
}

private struct TreeSingleValueEncodingContainer: SingleValueEncodingContainer {
    let sink: NodeRef
    var codingPath: [any CodingKey]

    mutating func encodeNil() throws { sink.node = .null }
    mutating func encode(_ value: Bool) throws { sink.node = .bool(value) }
    mutating func encode(_ value: String) throws { sink.node = .string(value) }
    mutating func encode(_ value: Double) throws { sink.node = .double(value) }
    mutating func encode(_ value: Float) throws { sink.node = .double(Double(value)) }
    mutating func encode(_ value: Int) throws { sink.node = .int(value) }
    mutating func encode(_ value: Int8) throws { sink.node = .int(Int(value)) }
    mutating func encode(_ value: Int16) throws { sink.node = .int(Int(value)) }
    mutating func encode(_ value: Int32) throws { sink.node = .int(Int(value)) }
    mutating func encode(_ value: Int64) throws { sink.node = .int(Int(value)) }
    mutating func encode(_ value: UInt) throws { sink.node = .int(Int(value)) }
    mutating func encode(_ value: UInt8) throws { sink.node = .int(Int(value)) }
    mutating func encode(_ value: UInt16) throws { sink.node = .int(Int(value)) }
    mutating func encode(_ value: UInt32) throws { sink.node = .int(Int(value)) }
    mutating func encode(_ value: UInt64) throws { sink.node = .int(Int(value)) }
    mutating func encode<T: Encodable>(_ value: T) throws {
        let child = NodeRef()
        try value.encode(to: TreeEncoder(sink: child, codingPath: codingPath))
        sink.node = child.node
    }
}

private final class TreeKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let sink: NodeRef
    let codingPath: [any CodingKey]
    private var members: [JSONNode.Member] = []

    init(sink: NodeRef, codingPath: [any CodingKey]) {
        self.sink = sink
        self.codingPath = codingPath
        sink.node = .object([])
    }

    private func append(_ node: JSONNode, _ key: Key) {
        members.append(JSONNode.Member(key: key.stringValue, value: node))
        sink.node = .object(members)
    }

    func encodeNil(forKey key: Key) throws { append(.null, key) }
    func encode(_ value: Bool, forKey key: Key) throws { append(.bool(value), key) }
    func encode(_ value: String, forKey key: Key) throws { append(.string(value), key) }
    func encode(_ value: Double, forKey key: Key) throws { append(.double(value), key) }
    func encode(_ value: Float, forKey key: Key) throws { append(.double(Double(value)), key) }
    func encode(_ value: Int, forKey key: Key) throws { append(.int(value), key) }
    func encode(_ value: Int8, forKey key: Key) throws { append(.int(Int(value)), key) }
    func encode(_ value: Int16, forKey key: Key) throws { append(.int(Int(value)), key) }
    func encode(_ value: Int32, forKey key: Key) throws { append(.int(Int(value)), key) }
    func encode(_ value: Int64, forKey key: Key) throws { append(.int(Int(value)), key) }
    func encode(_ value: UInt, forKey key: Key) throws { append(.int(Int(value)), key) }
    func encode(_ value: UInt8, forKey key: Key) throws { append(.int(Int(value)), key) }
    func encode(_ value: UInt16, forKey key: Key) throws { append(.int(Int(value)), key) }
    func encode(_ value: UInt32, forKey key: Key) throws { append(.int(Int(value)), key) }
    func encode(_ value: UInt64, forKey key: Key) throws { append(.int(Int(value)), key) }
    func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        let child = NodeRef()
        try value.encode(to: TreeEncoder(sink: child, codingPath: codingPath))
        append(child.node, key)
    }

    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        fatalError("TreeEncoder: nested keyed containers are unused by these tests")
    }
    func nestedUnkeyedContainer(forKey key: Key) -> any UnkeyedEncodingContainer {
        fatalError("TreeEncoder: nested unkeyed containers are unused by these tests")
    }
    func superEncoder() -> any Encoder {
        fatalError("TreeEncoder: superEncoder is unused by these tests")
    }
    func superEncoder(forKey key: Key) -> any Encoder {
        fatalError("TreeEncoder: superEncoder(forKey:) is unused by these tests")
    }
}

// MARK: Decoder

private struct TreeDecoder: Decoder {
    let node: JSONNode
    var codingPath: [any CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] { [:] }

    func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        guard case .object(let members) = node else {
            throw CodecError.shape("expected object, found \(node)")
        }
        return KeyedDecodingContainer(TreeKeyedDecodingContainer<Key>(members: members, codingPath: codingPath))
    }
    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        throw CodecError.shape("unkeyed containers are unused by these tests")
    }
    func singleValueContainer() throws -> any SingleValueDecodingContainer {
        TreeSingleValueDecodingContainer(node: node, codingPath: codingPath)
    }
}

private struct TreeSingleValueDecodingContainer: SingleValueDecodingContainer {
    let node: JSONNode
    var codingPath: [any CodingKey]

    func decodeNil() -> Bool {
        if case .null = node { return true } else { return false }
    }
    func decode(_ type: Bool.Type) throws -> Bool {
        guard case .bool(let value) = node else { throw CodecError.shape("expected Bool") }
        return value
    }
    func decode(_ type: String.Type) throws -> String {
        guard case .string(let value) = node else { throw CodecError.shape("expected String") }
        return value
    }
    func decode(_ type: Double.Type) throws -> Double {
        guard case .double(let value) = node else { throw CodecError.shape("expected Double") }
        return value
    }
    func decode(_ type: Float.Type) throws -> Float { Float(try decode(Double.self)) }
    func decode(_ type: Int.Type) throws -> Int {
        guard case .int(let value) = node else { throw CodecError.shape("expected Int") }
        return value
    }
    func decode(_ type: Int8.Type) throws -> Int8 { Int8(try decode(Int.self)) }
    func decode(_ type: Int16.Type) throws -> Int16 { Int16(try decode(Int.self)) }
    func decode(_ type: Int32.Type) throws -> Int32 { Int32(try decode(Int.self)) }
    func decode(_ type: Int64.Type) throws -> Int64 { Int64(try decode(Int.self)) }
    func decode(_ type: UInt.Type) throws -> UInt { UInt(try decode(Int.self)) }
    func decode(_ type: UInt8.Type) throws -> UInt8 { UInt8(try decode(Int.self)) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { UInt16(try decode(Int.self)) }
    func decode(_ type: UInt32.Type) throws -> UInt32 { UInt32(try decode(Int.self)) }
    func decode(_ type: UInt64.Type) throws -> UInt64 { UInt64(try decode(Int.self)) }
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try T(from: TreeDecoder(node: node, codingPath: codingPath))
    }
}

private struct TreeKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let members: [JSONNode.Member]
    var codingPath: [any CodingKey]

    var allKeys: [Key] { members.compactMap { Key(stringValue: $0.key) } }
    func contains(_ key: Key) -> Bool { members.contains { $0.key == key.stringValue } }

    private func single(_ key: Key) throws -> TreeSingleValueDecodingContainer {
        guard let member = members.first(where: { $0.key == key.stringValue }) else {
            throw CodecError.shape("missing key \(key.stringValue)")
        }
        return TreeSingleValueDecodingContainer(node: member.value, codingPath: codingPath)
    }

    func decodeNil(forKey key: Key) throws -> Bool { try single(key).decodeNil() }
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool { try single(key).decode(Bool.self) }
    func decode(_ type: String.Type, forKey key: Key) throws -> String { try single(key).decode(String.self) }
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double { try single(key).decode(Double.self) }
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float { try single(key).decode(Float.self) }
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int { try single(key).decode(Int.self) }
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 { try single(key).decode(Int8.self) }
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 { try single(key).decode(Int16.self) }
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 { try single(key).decode(Int32.self) }
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 { try single(key).decode(Int64.self) }
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt { try single(key).decode(UInt.self) }
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 { try single(key).decode(UInt8.self) }
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { try single(key).decode(UInt16.self) }
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { try single(key).decode(UInt32.self) }
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { try single(key).decode(UInt64.self) }
    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        guard let member = members.first(where: { $0.key == key.stringValue }) else {
            throw CodecError.shape("missing key \(key.stringValue)")
        }
        return try T(from: TreeDecoder(node: member.value, codingPath: codingPath))
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        fatalError("TreeDecoder: nested keyed containers are unused by these tests")
    }
    func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
        fatalError("TreeDecoder: nested unkeyed containers are unused by these tests")
    }
    func superDecoder() throws -> any Decoder {
        fatalError("TreeDecoder: superDecoder is unused by these tests")
    }
    func superDecoder(forKey key: Key) throws -> any Decoder {
        fatalError("TreeDecoder: superDecoder(forKey:) is unused by these tests")
    }
}
