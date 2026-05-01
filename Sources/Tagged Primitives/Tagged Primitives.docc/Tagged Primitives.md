# ``Tagged_Primitives``

@Metadata {
    @DisplayName("Tagged Primitives")
    @TitleHeading("Swift Institute — Primitives Layer")
}

Phantom-typed value wrappers for zero-cost type safety.

## Overview

Tagged Primitives provides ``Tagged``, a generic struct that wraps a raw
value with a compile-time phantom type parameter. The phantom `Tag` exists
only in the type system — it adds no runtime overhead, no storage, and no
indirection. What it adds is **type discrimination**: two values with the
same raw type but different tags are incompatible at compile time.

The tag is always an existing domain type — you do not create artificial
tag enums. The domain itself becomes the discriminator:

```swift
import Tagged_Primitives
import Ordinal_Primitives

typealias Index<Element> = Tagged<Element, Ordinal>
typealias Address = Tagged<Memory, Ordinal>

let graphIndex: Index<Graph> = ...
let bitIndex: Index<Bit> = ...
// graphIndex == bitIndex  // Compile error — Graph ≠ Bit
```

`Index<Graph>` and `Index<Bit>` both wrap `Ordinal`, but the phantom
parameter (`Graph` vs `Bit`) makes them incompatible types. The domain
*is* the tag.

The safety guarantee is a **theorem**, not a convention. Reynolds'
parametricity (1983) proves that any function polymorphic over `Tag` cannot
inspect, construct, or modify the tag. Wadler's free theorems (1989) prove
that tag-preserving operations cannot forge a different tag. These are
properties of the type system itself.

### Design Principles

- **Zero-cost abstraction.** `Tagged` stores exactly one field. With
  `@inlinable`, the compiler eliminates the wrapper at optimization time.
- **Operator non-forwarding is a feature.** Arithmetic on `RawValue` is
  not automatically available on `Tagged`. This prevents mixing incompatible
  domains — a graph index and a bit count may both wrap `Ordinal`, but
  adding them is meaningless.
- **Universal tag constraints.** Every extension uses `Tag: ~Copyable`,
  ensuring `Tagged` works for all tags — including tags parameterized by
  noncopyable element types like `Index<Element>` where `Element: ~Copyable`.
- **Noncopyable raw values.** `Tagged<Tag, RawValue: ~Copyable>` supports
  move-only wrapped values — a dimension neither stdlib's `RawRepresentable`
  nor `pointfreeco/swift-tagged` admits, since both predate noncopyable
  generics.

## Topics

### Core Type

- ``Tagged``

### Concepts

- <doc:Phantom-Tag-Semantics>
