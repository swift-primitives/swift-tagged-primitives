# Tagged Primitives Insights

<!--
---
title: Tagged Primitives Insights
version: 1.1.0
last_updated: 2026-04-24
applies_to: [swift-tagged-primitives]
normative: false
---
-->

Design decisions, implementation patterns, and lessons learned specific to this package. The package was renamed from `swift-identity-primitives` → `swift-tagged-primitives` (2026-04-21); historical reflection entries tagged with `[Package: swift-identity-primitives]` still apply here.

## Overview

This document captures insights that emerged during development of swift-tagged-primitives. These are not API requirements — they are recorded decisions and patterns that inform future work on this package.

**Document type**: Non-normative (recorded decisions, not requirements).

**Consolidation source**: Reflection entries tagged with `[Package: swift-tagged-primitives]` or the historical `[Package: swift-identity-primitives]`.

---

## Tagged's Lack of Operator Forwarding Is a Feature

**Date**: 2026-01-28

**Context**: Investigating why Index<E> + Index<E>.Count required explicit operators in Index Primitives when both types wrap primitives that already have the operator defined.

The question seemed simple: if `Ordinal + Cardinal → Ordinal` is defined in Ordinal Primitives, and `Index<E>` is just `Tagged<E, Ordinal>`, shouldn't the operator "just work"? It doesn't. Every operator on Tagged types must be explicitly declared.

Tagged's refusal to forward operators is deliberate type safety. Consider:

```swift
let graphIndex: Index<Graph> = ...
let bitCount: Index<Bit>.Count = ...
graphIndex + bitCount  // Should this compile?
```

If Tagged auto-forwarded based on Underlying, this would compile—both wrap compatible primitive types. But it's semantically meaningless to add a graph index and a bit count. The phantom type exists precisely to prevent this mixing.

The solution is elegant: extend Tagged with Underlying constraints at each primitives level:

```swift
extension Tagged where Underlying == Ordinal, Tag: ~Copyable {
    static func + (lhs: Self, rhs: Tagged<Tag, Cardinal>) -> Self { ... }
}
```

The `Tag: ~Copyable` with matching `Tagged<Tag, Cardinal>` ensures both operands share the same phantom type. The constraint is the feature—it's what makes the operator type-safe rather than just type-compatible.

**Applies to**: Tagged operator extensions, phantom type safety, why operators aren't auto-forwarded.

---

## The ~Copyable Constraint on Tag

**Date**: 2026-01-28

**Context**: Understanding why `Tag: ~Copyable` appears in every Tagged extension.

Every operator extension on Tagged includes `Tag: ~Copyable`:

```swift
extension Tagged where Underlying == Ordinal, Tag: ~Copyable { ... }
```

This seems redundant—why would a phantom type need a ~Copyable constraint? The answer lies in Swift's generic system. Without the constraint, the extension only applies when `Tag: Copyable`. With `Tag: ~Copyable`, it applies to all tags regardless of Copyable conformance.

`Index<Element>` where `Element: ~Copyable` is valid—you can have indices into containers of move-only types. If the Tagged extensions required `Tag: Copyable`, these indices would lose their operators. The `~Copyable` constraint ensures universality.

The explicit `Tag: ~Copyable` also serves as documentation. It signals "this extension works for all tags" rather than silently defaulting to Copyable-only. When reading the code, the constraint makes the design intent visible.

**Applies to**: All Tagged extensions, phantom type constraints, ~Copyable universality pattern.

---

## Related

- [Tagged.swift](../Sources/Tagged%20Primitives/Tagged.swift)
