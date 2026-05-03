# Tagged Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Phantom-typed value wrappers for zero-cost type safety — `Tagged<Tag, Underlying>` gives ecosystem types like `Index<Element>`, `Cardinal`, `Ordinal`, and `Hash.Value` their type-level identity without runtime cost, including across `~Copyable` and `~Escapable` underlying values.

> Forked from [`pointfreeco/swift-tagged`](https://github.com/pointfreeco/swift-tagged), Point-Free's phantom-typed wrapper that introduced the pattern in the Swift ecosystem. See [_Forked from: what heritage means at the Swift Institute_](https://swift-institute.org/documentation/swift-institute/forked-from) for the Institute's heritage discipline.

---

## Key Features

- **Zero-cost phantom discrimination** — `Tagged<Tag, Underlying>` stores exactly one field; with `@inlinable`, release-mode codegen is identical to the bare `Underlying` (verified in `Experiments/tagged-zero-cost-codegen`).
- **Operator non-forwarding is a feature** — arithmetic on `Underlying` is never automatically available on `Tagged`, preventing `Index<Graph> + Index<Bit>.Count` from compiling even though both wrap types with a defined `+`. Operations are declared per-domain with matching `Tag` constraints.
- **Universal `Tag: ~Copyable & ~Escapable`** — every extension lifts the tag's copyability and escapability constraints, so phantom-typed indices into `~Copyable` containers (`Index<Element>` where `Element: ~Copyable`) do not lose their operators.
- **`~Copyable` and `~Escapable` `Underlying`** — `Tagged` admits move-only and lifetime-bounded wrapped values; the ecosystem's typed pointers and scoped references (`Ownership.Inout`, `Ownership.Borrow`) wrap cleanly. Neither stdlib's `RawRepresentable` nor `pointfreeco/swift-tagged` admits this; both predate Swift's noncopyable-generics features (SE-0427, SE-0446).
- **`Ownership.Borrow.Protocol` conformance** — `Tagged<Tag, Underlying>` is `Ownership.Borrow.Protocol` when `Underlying` is; `Tagged.Borrowed` resolves to `Underlying.Borrowed`. The conformance is supplied by [`swift-ownership-primitives`](https://github.com/swift-primitives/swift-ownership-primitives) (the package that declares the protocol).
- **`Carrier.\`Protocol\`` cascading conformance** (ships in this package) — `Tagged<Tag, Underlying>` conforms to `Carrier.\`Protocol\`` when `Underlying` does, with `Tagged.Underlying` resolving through `Underlying.Underlying`. APIs declared as `some Carrier.\`Protocol\`<Cardinal>` (or the alias `some Carrying<Cardinal>`) accept bare `Cardinal` AND `Tagged<Tag, Cardinal>` uniformly; nested wrappers like `Tagged<X, Tagged<Y, Cardinal>>` resolve to the innermost trivial-self carrier. The phantom `Tag` becomes Carrier's `Domain` discriminator. External access to the wrapped value flows through `tagged.underlying` (the Carrier accessor); construction flows through `Tagged<Tag, U>(value)` (the Carrier init).

---

## Quick Start

### Domain-identity without a parallel struct

```swift
import Tagged_Primitives

public enum User {}
public enum Order {}

extension User  { public typealias ID = Tagged<User,  UInt64> }
extension Order { public typealias ID = Tagged<Order, UInt64> }

let user:  User.ID  = 42
let order: Order.ID = 42
// user == order         // Compile error: Tagged<User, ...> ≠ Tagged<Order, ...>
```

The hand-rolled equivalent per domain — one struct, one init, one `underlying` accessor, one conformance stack — multiplied across every ID type in the system. `Tagged` collapses it to one declaration.

### Phantom-typed indices into `~Copyable` containers

```swift
import Tagged_Primitives
import Ordinal_Primitives

public enum File {}
extension File {
    public struct Descriptor: ~Copyable { /* resource handle */ }
}

typealias Index<Element: ~Copyable & ~Escapable> = Tagged<Element, Ordinal>

let fd:   Index<File.Descriptor> = 3
let byte: Index<UInt8>           = 3
// fd == byte           // Compile error: File.Descriptor tag ≠ UInt8 tag
```

`Tag: ~Copyable & ~Escapable` on every extension means the index type works whether the element is `Copyable`, `~Copyable`, `Escapable`, or `~Escapable`.

### Functor operations — `map` and `retag`

```swift
import Tagged_Primitives

let id: User.ID = 42

let asString: Tagged<User, String> = id.map { String($0) }   // preserve Tag, transform Underlying
let asOrder:  Order.ID             = id.retag()              // preserve Underlying, change Tag (explicit coercion)
```

`retag` is a phantom coercion — with `@inlinable`, the optimizer eliminates the call. It is a meaningful operation for domain-identity wrappers because crossing domains IS the intent. (Contrast: [`Property<Tag, Base>`](https://github.com/swift-primitives/swift-property-primitives) uses the tag as a verb namespace, not a domain identity — retagging makes no sense there.)

`Tagged.map` uses typed throws (`throws(E) where E: Error`); the error type is part of the signature, not erased to `any Error`:

```swift
struct ParseError: Error { let message: String }

func parseUserID(_ raw: String) throws(ParseError) -> User.ID {
    guard let n = UInt64(raw) else { throw ParseError(message: "not a number") }
    return User.ID(n)   // Carrier init — accepts the cascade-end Underlying
}

let id: Tagged<User, String> = "42"
let parsed: User.ID = try id.map { raw throws(ParseError) in
    guard let n = UInt64(raw) else { throw ParseError(message: "not a number") }
    return n
}
```

External construction flows through the `Carrier.\`Protocol\``-derived public init `Tagged<Tag, U>(_ underlying:)` (when `U` conforms to `Carrier.\`Protocol\``). Domain types layer custom validated initializers on top; the package-internal `init(_unchecked:)` exists only for SLI conformances and per-domain types declared inside this package — external consumers should not reach for it.

Consumers who need a `Result`-shaped outcome wrap at the call site: `Result(catching: { try id.map(transform) })`.

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-tagged-primitives.git", branch: "main")
]
```

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
        // Optional — opt into stdlib protocol conformances:
        // .product(name: "Tagged Primitives Standard Library Integration", package: "swift-tagged-primitives"),
    ]
)
```

Requires Swift 6.3.1 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the matching Linux / Windows toolchain).

---

## Architecture

Three library products: `Tagged Primitives` (the umbrella), `Tagged Primitives Standard Library Integration` (opt-in stdlib conformances), and `Tagged Primitives Test Support` (test-only fixtures, re-exports SLI for ergonomic test code).

### Main target (`Tagged Primitives`)

| File | Purpose |
|------|---------|
| `Tagged.swift` | The `Tagged<Tag: ~Copyable & ~Escapable, Underlying: ~Copyable & ~Escapable>` struct, functor operations (`map`, `retag`), and conditional conformances (`Sendable`, `Equatable`, `Hashable`, `Comparable`, `Codable`, `BitwiseCopyable`). The body holds only `_storage` (package-internal) and `init(_unchecked:)` (package-internal); all read/write surface flows through extensions. |
| `Tagged+CustomStringConvertible.swift` | `CustomStringConvertible` forwarded to the underlying value. |
| `Tagged+Carrier.Protocol.swift` | `Carrier.\`Protocol\`` cascading conformance — `Tagged.Underlying` resolves through `Underlying.Underlying`, lifting every Tagged-aliased ecosystem type into the `Carrier.\`Protocol\`` family. The phantom `Tag` becomes the `Domain` discriminator. Provides the public `underlying` accessor and `init(_:)` for external consumers. |

### Standard Library Integration target (`Tagged Primitives Standard Library Integration`)

Opt-in via `import Tagged_Primitives_Standard_Library_Integration` (which re-exports `Tagged_Primitives` so consumers don't double-import).

| File | Conformance |
|------|-------------|
| `Tagged+Literals.swift` | The 7 stdlib literal protocols (`ExpressibleByIntegerLiteral`, `ExpressibleByFloatLiteral`, `ExpressibleByBooleanLiteral`, `ExpressibleByStringLiteral`, `ExpressibleByUnicodeScalarLiteral`, `ExpressibleByExtendedGraphemeClusterLiteral`, `ExpressibleByStringInterpolation`) — bundled because they share `@_disfavoredOverload` discipline as a cohesive opt-in family — **plus** `ExpressibleByArrayLiteral` and `ExpressibleByDictionaryLiteral` via a documented `unsafeBitCast` carve-out. This is the package's only exception to its otherwise-strict memory-safety stance; bounded scope (function-type reinterpretation between variadic and array forms only); marked with the `unsafe` expression keyword. See the file's MARK block and [`Research/principled-absence-array-dict-literal.md`](./Research/principled-absence-array-dict-literal.md) for provenance and ABI commitment status. |
| `Tagged+Identifiable.swift` | `Identifiable` (forwards `id` to `underlying.id`; carries the documented identity-inversion trade-off). |
| `Tagged+LosslessStringConvertible.swift` | `LosslessStringConvertible` (`init?(_:)` parses, `description` from main's `CustomStringConvertible`; lossy-from-Tagged-perspective trade-off documented). |
| `Tagged+Sequence.swift` | `Sequence` (forwards `makeIterator`; wrapper-vs-content conflation trade-off documented). |
| `Tagged+Collection.swift` | `Collection` (forwards `startIndex` / `endIndex` / `subscript` / `index(after:)`). |

### Deliberate absences

Some SLI conformances are deliberately absent where they would imply Foundation dependencies, invalid semantics, or unsupported forwarding. See [`Research/sli-deliberate-absences.md`](./Research/sli-deliberate-absences.md) for the catalogue (three categories, ten entries, each linking to a research doc + paired experiment).

### Dependencies

The single direct dependency, `swift-carrier-primitives`, provides the `Carrier.\`Protocol\`` capability protocol that `Tagged: Carrier.\`Protocol\`` cascades through. Other ecosystem-specific conformances on `Tagged` (`Ordinal.Protocol`, `Ownership.Borrow.Protocol`, etc.) live in the respective protocol / capability packages that import `swift-tagged-primitives`.

### Stability

`swift-tagged-primitives` follows SemVer pre-release semantics in 0.x.

| Surface | 0.1.x expectation |
|---|---|
| Public type names | Stable within 0.1.x |
| Documented initializers, functor operations, and conformance set (main + SLI) | Stable within 0.1.x; additive changes (new conformances) may land in patch releases |
| Internal storage shapes / `unsafeBitCast` carve-out scope / fork-heritage choreography | Not part of the source-stability commitment |

---

## Platform Support

| Platform | Status |
|----------|--------|
| macOS 26 | Full support |
| Linux | Full support |
| Windows | Full support |
| iOS / tvOS / watchOS / visionOS | Supported |
| Swift Embedded | Supported |

---

## Related Packages

**Used By**:

- [swift-ordinal-primitives](https://github.com/swift-primitives/swift-ordinal-primitives) — `Ordinal` + `Tagged<T, Ordinal>` give typed positions (`Index<Element>`, `Memory.Address`, `Bit.Index`). Also extends `Tagged` with `Ordinal.Protocol` conformance when `Underlying == Ordinal`.
- [swift-cardinal-primitives](https://github.com/swift-primitives/swift-cardinal-primitives) — `Cardinal` + `Tagged<T, Cardinal>` give typed quantities (`Index<T>.Count`, `Memory.Address.Count`).
- [swift-affine-primitives](https://github.com/swift-primitives/swift-affine-primitives) — `Affine.Discrete.Vector` + `Tagged<T, Affine.Discrete.Vector>` give typed displacements (`Index<T>.Offset`).
- [swift-ownership-primitives](https://github.com/swift-primitives/swift-ownership-primitives) — ships the `Tagged: Ownership.Borrow.Protocol` conformance in its `Ownership Borrow Primitives` target, so `Tagged<Tag, X>.Borrowed` resolves to `X.Borrowed` whenever `X` is borrow-capable.
- [swift-property-primitives](https://github.com/swift-primitives/swift-property-primitives) — `Property.View` stores `Tagged<Tag, Ownership.Inout<Base>>` as the canonical fluent-accessor shape.
- [swift-hash-primitives](https://github.com/swift-primitives/swift-hash-primitives), [swift-binary-primitives](https://github.com/swift-primitives/swift-binary-primitives), and every other primitives package that reaches for phantom-typed discrimination.

**Dependencies**:

- `swift-carrier-primitives` — the `Carrier` capability protocol that `Tagged: Carrier` cascades through (declared in `Package.swift`).

---

## License

Apache 2.0 (Institute) with MIT attribution to the upstream `pointfreeco/swift-tagged` (Copyright (c) 2019 Point-Free, Inc.). The combined-license text — Institute Apache 2.0 + the upstream's preserved MIT block — is in [LICENSE.md](LICENSE.md). MIT requires preservation of the original copyright notice in derivative works; the Institute's Apache 2.0 governs new contributions on top of the fork point.
