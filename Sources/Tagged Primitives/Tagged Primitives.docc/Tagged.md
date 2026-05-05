# ``Tagged``

@Metadata {
    @DisplayName("Tagged")
    @TitleHeading("Tagged Primitives")
}

A value wrapped with a compile-time phantom type tag.

## Overview

`Tagged<Tag, Underlying>` provides zero-cost type safety by wrapping an
underlying value with a phantom `Tag` parameter that exists only at compile
time. The tag is always a meaningful domain type — the domain *is* the
discriminator:

```swift
import Tagged_Primitives
import Ordinal_Primitives

typealias Index<Element> = Tagged<Element, Ordinal>

let graphIndex: Index<Graph> = ...
let bitIndex: Index<Bit> = ...
// graphIndex + bitIndex  // Compile error — Graph ≠ Bit
```

### Theoretical Foundation

Phantom types have a 40-year theoretical lineage. The safety of `Tagged`
rests on two foundational results:

- **Parametricity** (Reynolds, 1983): A function polymorphic over `Tag`
  cannot inspect, construct, or modify the tag. The phantom parameter is
  informationally inert at runtime.
- **Free theorems** (Wadler, 1989): Any function `f : Tagged<A, V> →
  Tagged<A, V>` polymorphic in `A` must preserve the tag — it cannot
  forge a `Tagged<B, V>` from a `Tagged<A, V>`.

Leijen & Meijer (1999) originated the phantom type pattern for embedded
DSLs. Fluet & Pucella (2006) proved phantom types can encode arbitrary
finite subtyping hierarchies. Cheney & Hinze (2003) showed them as a
precursor to GADTs. `Tagged` is the simplest instantiation: a
single-constructor type with one phantom index.

### Operator Non-Forwarding

`Tagged` deliberately does not forward operators from `Underlying`. This is
a type safety feature, not a limitation.

If operators forwarded automatically, `Index<Graph> + Index<Bit>.Count`
would compile — both wrap types with a defined `+` operator. But adding a
graph index to a bit count is semantically meaningless. The phantom type
exists precisely to prevent this mixing.

Operations are instead defined per-domain with explicit tag constraints:

```swift
import Tagged_Primitives
import Ordinal_Primitives
import Cardinal_Primitives

extension Tagged where Underlying == Ordinal, Tag: ~Copyable {
    static func + (lhs: Self, rhs: Tagged<Tag, Cardinal>) -> Self { ... }
}
```

The matching `Tag` on both operands enforces that only same-domain
operations are permitted.

### Functor Operations

`Tagged` supports two type-changing operations:

- ``Tagged/map(_:)-7mqjt`` transforms the underlying value while preserving
  the tag: `Tagged<Tag, V> → Tagged<Tag, W>`.
- ``Tagged/retag(_:)`` changes the tag while preserving the underlying
  value: `Tagged<A, V> → Tagged<B, V>`.

`retag` is a phantom coercion — it changes only the type-level tag with
no effect on the stored value. With `@inlinable` and optimization, the
compiler eliminates the call entirely. Unlike Haskell's `coerce` (which
the language guarantees is zero-cost via the `Coercible` type class and
role system), Swift's elimination depends on optimizer behavior. In
practice, the optimizer reliably eliminates the wrapper in release builds.

### Noncopyable Support

`Tagged<Tag: ~Copyable, Underlying: ~Copyable>` supports noncopyable
(affine) types in both the tag and value positions. The combination is
uncommon in phantom-type implementations elsewhere: Haskell has
no move semantics in its base type system, Rust's `PhantomData` requires
a zero-sized type for the phantom field, and OCaml and TypeScript have
no substructural types.

The `Tag: ~Copyable` constraint is semantically significant. It enables
`Index<Element>` where `Element: ~Copyable` — type-safe indices into
containers of move-only values. Without this constraint, the phantom type
system would silently exclude noncopyable element types from indexed
access.

### Cross-Language Context

The phantom-typed value wrapper pattern appears across ecosystems under
different names:

| Language | Mechanism | Zero-Cost | Operator Forwarding |
|----------|-----------|-----------|---------------------|
| Haskell | `newtype` + `Coercible` | Language-guaranteed | Automatic (`deriving`) |
| Rust | `PhantomData<T>` + `repr(transparent)` | ABI-guaranteed | Manual (macros) |
| OCaml | Module-level type abstraction | Optimization-dependent | Manual |
| TypeScript | Branded intersection types | Type erasure | Free (structural) — but no operation safety |
| Swift | Phantom generic parameter | Optimization-dependent (`@inlinable`) | Manual (protocol abstraction) |

Swift lacks Haskell's `Coercible` / role system and Rust's
`repr(transparent)` ABI guarantee. The protocol abstraction pattern
(see `Cardinal.Protocol`, `Ordinal.Protocol`) is the ecosystem's
mitigation for operator forwarding.

## Research

- [Tagged Literal Conformances](../../Research/tagged-literal-conformances.md) — Should Tagged conform to ExpressibleByIntegerLiteral in production? Status: DECISION.
- [Comparative Analysis: swift-tagged-primitives vs pointfreeco/swift-tagged](../../Research/comparative-analysis-pointfree-swift-tagged.md) — Systematic comparison across eight dimensions. Status: DECISION.

## Experiments

- [tagged-noncopyable-rawvalue](../../Experiments/tagged-noncopyable-rawvalue/) — Verify Tagged can support ~Copyable Underlying. Status: CONFIRMED.
- [tagged-zero-cost-codegen](../../Experiments/tagged-zero-cost-codegen/) — Verify Tagged produces identical codegen to underlying values at -O. Status: CONFIRMED.
- [tagged-literal-negative-ordinal](../../Experiments/tagged-literal-negative-ordinal/) — Verify UInt-backed Tagged types reject negative literals at compile time. Status: CONFIRMED.

## Topics

### Constructing and accessing

External construction and read-access flow through `Carrier.\`Protocol\``
(when `Underlying: Carrier.\`Protocol\``):

- `Tagged.init(_ underlying:)` — public, supplied by the Carrier conformance
- `Tagged.underlying` — public, supplied by the Carrier conformance

### Transforming

- ``Tagged/map(_:)-7mqjt``
- ``Tagged/retag(_:)-e9ql``
- ``Tagged/map(_:transform:)``
- ``Tagged/retag(_:to:)``
