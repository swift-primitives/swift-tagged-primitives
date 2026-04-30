# Phantom Tag Semantics

@Metadata {
    @TitleHeading("Swift Primitives")
}

`Tagged` and ``Property`` (from `swift-property-primitives`) are
structurally isomorphic: each is a single-field wrapper parameterized by
a phantom `Tag` and a value type. They look the same. They do different
jobs. Understanding the difference is how you pick the right primitive.

## Structural equivalence

```swift
// swift-tagged-primitives (this package)
public struct Tagged<Tag: ~Copyable, RawValue: ~Copyable>: ~Copyable {
    public var rawValue: RawValue
}

// swift-property-primitives
public struct Property<Tag, Base: ~Copyable>: ~Copyable {
    @usableFromInline internal var _base: Base
}
extension Property where Base: ~Copyable {
    public var base: Base { _read { yield _base } _modify { yield &_base } }
}
```

Both wrap a value (`rawValue` / `_base`), both discriminate on a phantom
`Tag`. Parameter order is identical: discriminator first, value second.

So what distinguishes them?

## Two semantic roles of the phantom tag

The distinction is what the phantom tag *discriminates*.

| | `Tagged` (this package) | `Property` |
|---|----------|------------|
| What the tag discriminates | **Domain identity** of the value | **Verb namespace** dispatched via extensions |
| Example | `Index<Graph>` ≠ `Index<Bit>` — different indices in different domains | `Property<Push, Stack>` vs `Property<Pop, Stack>` — same stack, different namespace |
| Tag values typical | Existing domain types (`Graph`, `Bit`, `UserID`) | Empty enums defined per-container (`enum Push {}`) |
| Meaningful ops on tag | `retag<NewTag>` (phantom coercion is meaningful) | None — retagging `Push` to `Pop` would be semantically nonsensical |
| Extension surface | Per-domain API (`extension Tagged where Tag == Ordinal { ... }`) | Per-namespace API (`extension Property where Tag == Stack<E>.Push { mutating func back(...) }`) |

`Tagged` gives values *identity* — the same operations apply; the tag
says what kind of thing the value is. Bring a `rawValue` through
without losing its domain. `retag<NewTag>` is the canonical meaningful
operation.

`Property` gives values *operations* — the container is the same; the
tag says what you can do with it.

## The taxonomy: domain-identity vs verb-namespace wrappers

The distinction has a name. **Domain-identity phantom wrapper** (this
package's `Tagged`) and **verb-namespace phantom wrapper**
(`Property`) describe two semantically distinct uses of the same
underlying mechanism. The terminology isn't established in the
academic phantom-types literature — the canonical research at
`swift-property-primitives/Research/property-tagged-semantic-roles.md`
analyzes 36 papers and finds no prior distinction at this level. Both
primitives ship together precisely because the distinction is real
and unavoidable.

The cross-reference also matters in the other direction: see
``Property``'s `Phantom Tag Semantics` article for the same
taxonomy from the verb-namespace perspective.

## Why two types instead of one

A unified `PhantomTagged<Tag, Value, Role>` with a `Role` type
parameter has been considered and rejected. The problem is
extension-namespace pollution: extensions on the verb-namespace role
would bleed into domain-identity sites with the same tag.

Keeping `Tagged` and `Property` as separate nominal types preserves
extension-namespace isolation. Extensions on `Property<Push, Stack>`
cannot be seen from `Tagged` consumers; extensions on `Tagged<Ordinal, Int>`
cannot be seen from `Property` consumers.

The categorical reason: the verb-namespace family's fibers are
*sealed* (no morphisms between Push and Pop), while the domain-identity
family's fibers are *connected* (`retag` is the cross-fiber morphism).
Lumping them under one type would force the verb-namespace's
"no cross-fiber morphisms" property to be re-established by extension
hygiene rather than by the type system — a discipline Swift's
overlap-rules cannot enforce.

See `swift-property-primitives/Research/property-tagged-semantic-roles.md`
v1.1.0+ for the full categorical-asymmetry argument.

## How to use the tags

### Tagged tags (domain identity)

- **Pre-existing domain types**, not purpose-built empty enums:
  `Graph`, `UserID`, `Bit`, `Ordinal`.
- **`retag<NewTag>` is a real operation** — crossing from `Index<Graph>`
  to `Index<Bit>` is a meaningful explicit coercion.
- **Extensions are per-domain, not per-namespace**.

```swift
typealias UserID = Tagged<User, UInt64>
typealias OrderID = Tagged<Order, UInt64>

extension Tagged where Tag == User {
    var isGuest: Bool { rawValue == 0 }
}
```

### Property tags (verb namespace, for contrast)

- **Empty enums nested on the container**: `Stack<E>.Push`, `Deque<E>.Peek`.
- **No `*Tag` suffix** — use `Push`, not `PushTag` (per
  `feedback_no_tag_suffix`).
- **Extensions are per-verb-namespace, not per-domain**.

See ``Property``'s Phantom Tag Semantics article for full guidance.

## Decision test

If your tag is an existing domain type that names what kind of value
you're wrapping (`UserID`, `Ordinal`, `Index<Graph>`) and you want
per-domain operations — you want **`Tagged`** (this package).

If your tag is a purpose-built empty enum that names an operation
(`Push`, `Peek`, `Insert`, `ForEach`) and you want a distinct set of
extensions for it — you want **``Property``**.

The two are co-abstractions, not competitors. Many primitives consume
both.

## See Also

- ``Tagged``
- `swift-property-primitives/Research/property-tagged-semantic-roles.md` (canonical research)
- `swift-carrier-primitives/Research/capability-lift-pattern.md` (super-protocol unification analysis — outcome: deferred)
