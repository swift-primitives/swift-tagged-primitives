# Tagged Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Phantom-typed value wrappers for zero-cost type safety — `Tagged<Tag, RawValue>` gives ecosystem types like `Index<Element>`, `Cardinal`, `Ordinal`, and `Hash.Value` their type-level identity without runtime cost, including across `~Copyable` and `~Escapable` raw values.

> Forked from [`pointfreeco/swift-tagged`](https://github.com/pointfreeco/swift-tagged). The Institute fork keeps the `Tagged<Tag, RawValue>` shape but constrains the default conformance surface: `~Copyable` and `~Escapable` are admitted on both parameters, Foundation is excluded, and operator forwarding is removed (so `Index<Graph> + Index<Bit>` won't compile). The fork is heritage-only — divergences are principled and permanent; upstream changes are re-authored, not merged. See [`Research/comparative-analysis-pointfree-swift-tagged.md`](./Research/comparative-analysis-pointfree-swift-tagged.md) for the per-dimension divergence rationale.

---

## Key Features

- **Zero-cost phantom discrimination** — `Tagged<Tag, RawValue>` stores exactly one field; with `@inlinable`, release-mode codegen is identical to the underlying `RawValue` (verified in `Experiments/tagged-zero-cost-codegen`).
- **Operator non-forwarding is a feature** — arithmetic on `RawValue` is never automatically available on `Tagged`, preventing `Index<Graph> + Index<Bit>.Count` from compiling even though both wrap types with a defined `+`. Operations are declared per-domain with matching `Tag` constraints.
- **Universal `Tag: ~Copyable & ~Escapable`** — every extension lifts the tag's copyability and escapability constraints, so phantom-typed indices into `~Copyable` containers (`Index<Element>` where `Element: ~Copyable`) do not lose their operators.
- **`~Copyable` and `~Escapable` `RawValue`** — `Tagged` admits move-only and lifetime-bounded wrapped values; the ecosystem's typed pointers and scoped references (`Ownership.Inout`, `Ownership.Borrow`) wrap cleanly. Neither stdlib's `RawRepresentable` nor `pointfreeco/swift-tagged` admits this; both predate Swift's noncopyable-generics features (SE-0427, SE-0446).
- **`Ownership.Borrow.Protocol` conformance** (ships with `swift-ownership-primitives`) — `Tagged<Tag, RawValue>` is `Ownership.Borrow.Protocol` when `RawValue` is; `Tagged.Borrowed` resolves to `RawValue.Borrowed`. The conformance lives in `swift-ownership-primitives/Sources/Ownership Borrow Primitives/`, matching the ecosystem convention where conformances of Tagged to non-stdlib capability protocols live with the protocol's home package (see `swift-ordinal-primitives` for the same pattern with `Ordinal.Protocol`).
- **`Carrier` cascading conformance** (ships in this package) — `Tagged<Tag, RawValue>` is `Carrier` when `RawValue` is, with `Underlying` cascading through `RawValue.Underlying`. APIs declared as `some Carrier<Cardinal>` accept bare `Cardinal` AND `Tagged<Tag, Cardinal>` uniformly; nested wrappers like `Tagged<X, Tagged<Y, Cardinal>>` resolve to the innermost trivial-self carrier. The phantom `Tag` becomes Carrier's `Domain` discriminator.

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

The hand-rolled equivalent per domain — one struct, one init, one `rawValue` accessor, one conformance stack — multiplied across every ID type in the system. `Tagged` collapses it to one declaration.

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

let asString: Tagged<User, String> = id.map { String($0) }   // preserve Tag, transform RawValue
let asOrder:  Order.ID             = id.retag()              // preserve RawValue, change Tag (explicit coercion)
```

`retag` is a phantom coercion — with `@inlinable`, the optimizer eliminates the call. It is a meaningful operation for domain-identity wrappers because crossing domains IS the intent. (Contrast: the sibling `Property<Tag, Base>` type in `swift-property-primitives` uses the tag as a *verb namespace* — retagging `Push` to `Pop` would be semantically nonsensical. The `Phantom Tag Semantics` DocC article in this package's catalog details the two-role taxonomy.)

`Tagged.map` uses typed throws (`throws(E) where E: Error`); the error type is part of the signature, not erased to `any Error`:

```swift
struct ParseError: Error { let message: String }

func parseUserID(_ raw: String) throws(ParseError) -> User.ID {
    guard let n = UInt64(raw) else { throw ParseError(message: "not a number") }
    return User.ID(__unchecked: (), n)
}

let id: Tagged<User, String> = "42"
let parsed: User.ID = try id.map { raw throws(ParseError) in
    guard let n = UInt64(raw) else { throw ParseError(message: "not a number") }
    return n
}
```

Consumers who need a `Result`-shaped outcome wrap at the call site: `Result(catching: { try id.map(transform) })`.

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-tagged-primitives.git", from: "0.1.0")
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

> **Pre-tag note**: this package's `Package.swift` currently pins its single dependency `swift-carrier-primitives` to `branch: "main"` as a publication-ready interim. The dependency will graduate to `from: "0.1.0"` once `swift-carrier-primitives` cuts its 0.1.0 tag (the two packages are part of the same release cohort). Consumers using the snippet above will resolve cleanly once both tags are in place.

---

## Architecture

Three library products: `Tagged Primitives` (the umbrella), `Tagged Primitives Standard Library Integration` (opt-in stdlib conformances), and `Tagged Primitives Test Support` (test-only fixtures, re-exports SLI for ergonomic test code).

### Main target (`Tagged Primitives`)

| File | Purpose |
|------|---------|
| `Tagged.swift` | The `Tagged<Tag: ~Copyable & ~Escapable, RawValue: ~Copyable & ~Escapable>` struct, functor operations (`map`, `retag`), and conditional conformances (`Sendable`, `Equatable`, `Hashable`, `Comparable`, `Codable`, `BitwiseCopyable`). |
| `Tagged+CustomStringConvertible.swift` | `CustomStringConvertible` forwarded to the raw value. |
| `Tagged+Carrier.swift` | `Carrier` cascading conformance — `Tagged.Underlying` resolves through `RawValue.Underlying`, lifting every Tagged-aliased ecosystem type into the `Carrier` family. The phantom `Tag` becomes the `Carrier` `Domain` discriminator. |

### Standard Library Integration target (`Tagged Primitives Standard Library Integration`)

Opt-in via `import Tagged_Primitives_Standard_Library_Integration` (which re-exports `Tagged_Primitives` so consumers don't double-import).

| File | Conformance |
|------|-------------|
| `Tagged+Literals.swift` | The 7 stdlib literal protocols (`ExpressibleByIntegerLiteral`, `ExpressibleByFloatLiteral`, `ExpressibleByBooleanLiteral`, `ExpressibleByStringLiteral`, `ExpressibleByUnicodeScalarLiteral`, `ExpressibleByExtendedGraphemeClusterLiteral`, `ExpressibleByStringInterpolation`) — bundled because they share `@_disfavoredOverload` discipline as a cohesive opt-in family — **plus** `ExpressibleByArrayLiteral` and `ExpressibleByDictionaryLiteral` via a documented `unsafeBitCast` carve-out. This is the package's only exception to its otherwise-strict memory-safety stance; bounded scope (function-type reinterpretation between variadic and array forms only); marked with the `unsafe` expression keyword. See the file's MARK block and [`Research/principled-absence-array-dict-literal.md`](./Research/principled-absence-array-dict-literal.md) for provenance and ABI commitment status. |
| `Tagged+Identifiable.swift` | `Identifiable` (forwards `id` to `rawValue.id`; carries the documented identity-inversion trade-off). |
| `Tagged+LosslessStringConvertible.swift` | `LosslessStringConvertible` (`init?(_:)` parses, `description` from main's `CustomStringConvertible`; lossy-from-Tagged-perspective trade-off documented). |
| `Tagged+Sequence.swift` | `Sequence` (forwards `makeIterator`; wrapper-vs-content conflation trade-off documented). |
| `Tagged+Collection.swift` | `Collection` (forwards `startIndex` / `endIndex` / `subscript` / `index(after:)`). |

### Excluded from SLI

The conformances absent from SLI fall into three categories. **Structural Swift-level blockers**: `RawRepresentable` (not authorable on Swift 6.3.1 due to `~Escapable` non-awareness) and `@dynamicMemberLookup` (a type-declaration attribute, not retroactive on extensions). **Foundation axiom**: `LocalizedError` and `UUID` convenience inits would require importing Foundation, which the primitives layer doesn't do. **Policy trade-off**: `AdditiveArithmetic` / `Numeric` family (operator-forwarding footgun on cross-domain arithmetic — the very property the fork's "operator non-forwarding is a feature" stance protects against), `Strideable` (SLI-excluded to keep the literal-conformance footgun dormant for SLI-only consumers; documented in [`Research/sli-literal-vs-strideable-tradeoff.md`](./Research/sli-literal-vs-strideable-tradeoff.md)), and the niche / already-covered protocols `CustomPlaygroundDisplayConvertible` / `CodingKeyRepresentable` / Decodable's double-try fallback. Each absence has a research doc + paired experiment under `Research/principled-absence-*.md` and `Experiments/tagged-no-*/` (10 + 10), classifying it as HARD blocker, SOFT-shipped-in-SLI, or SOFT-excluded-by-policy with empirical evidence.

### Dependencies

The single direct dependency, `swift-carrier-primitives`, provides the `Carrier` capability protocol that `Tagged: Carrier` cascades through. Other ecosystem-specific conformances on `Tagged` (`Ordinal.Protocol`, `Ownership.Borrow.Protocol`, etc.) live in the respective protocol / capability packages that import `swift-tagged-primitives`.

### Versioning and stability

The 0.1.x line commits to the conformance set documented above: main ships the unconditional + conditional conformances on `Tagged`, SLI ships exactly the 5 forwarding conformances + 9 literal conformances enumerated, and Test Support re-exports both. **Additive changes** within 0.1.x — new conformances on `Tagged` shipped in main or SLI — are non-breaking and may land in patch releases; the per-protocol absence catalog is the inventory of candidates. **Removals or scope reductions** require a minor-version bump (0.2.0+). The `unsafeBitCast` carve-out's scope is bounded to its current two sites; widening the carve-out to a third site requires a minor-version bump and a new entry in the per-protocol absence catalog. The fork-as-heritage shape is structural and permanent; the package does not merge upstream changes, so upstream's release cadence does not affect this package's SemVer trajectory.

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

- [swift-ordinal-primitives](https://github.com/swift-primitives/swift-ordinal-primitives) — `Ordinal` + `Tagged<T, Ordinal>` give typed positions (`Index<Element>`, `Memory.Address`, `Bit.Index`). Also extends `Tagged` with `Ordinal.Protocol` conformance when `RawValue == Ordinal`.
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
