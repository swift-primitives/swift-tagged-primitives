// Experiment: Tagged is not @dynamicMemberLookup. Empirically classify.
//
// Demonstrates the principled absence rationale documented in
// `Research/principled-absence-dynamicmemberlookup.md`.
//
// (a) ABSENCE PROOF: without @dynamicMemberLookup on Tagged, accessing a
//     wrapped value's property via `tagged.someProperty` does NOT compile —
//     Tagged has no such member. The wrapper boundary is enforced.
//
// (b) RETROACTIVE-ATTRIBUTE TEST: @dynamicMemberLookup must be on the type
//     declaration, not added via extension. So even a consumer-side
//     "opt-in" attempt is structurally not authorable. (Documented in
//     `reject-test-retroactive-attribute.swift.txt`.)
//
// (c) EXPLICIT UNWRAP (recommended pattern): tagged.rawValue.name marks
//     the type boundary at every access. Aligns with the explicit-unwrap
//     pattern recommended for Sequence/Collection.
//
// Verified: Swift 6.3.1 (Apple Swift on macOS) — 2026-04-30.

import Tagged_Primitives

// MARK: - Domain setup

struct Profile {
    let name: String
    let age: Int
    let city: String
}

enum User {}
extension User { typealias Wrapped = Tagged<User, Profile> }

let user = Profile(name: "Alice", age: 30, city: "Paris")
let taggedUser: User.Wrapped = User.Wrapped(__unchecked: (), user)

// MARK: - Absence proof
//
// `taggedUser.name` does NOT compile. The reject-test file
// `reject-test-no-passthrough.swift.txt` documents the diagnostic.
//
// Without @dynamicMemberLookup, Tagged's surface is what's declared on
// the struct: `rawValue` and the conformance-derived methods.

// Verify available members:
let raw = taggedUser.rawValue              // OK — declared property
precondition(raw.name == "Alice", "rawValue access works (it's declared on Tagged)")

print("tagged-no-dynamicmemberlookup: Tagged has no `name` member; `taggedUser.name` does NOT compile (see reject-test).")

// MARK: - Explicit unwrap pattern (recommended)

let nameViaUnwrap = taggedUser.rawValue.name
let ageViaUnwrap  = taggedUser.rawValue.age
let cityViaUnwrap = taggedUser.rawValue.city

precondition(nameViaUnwrap == "Alice")
precondition(ageViaUnwrap == 30)
precondition(cityViaUnwrap == "Paris")

print("tagged-no-dynamicmemberlookup: explicit unwrap pattern works — every .rawValue marks the type-boundary crossing.")
print("   tagged.rawValue.name = \(nameViaUnwrap)")
print("   tagged.rawValue.age = \(ageViaUnwrap)")
print("   tagged.rawValue.city = \(cityViaUnwrap)")

// MARK: - Consumer alternative — wrapper struct with own @dynamicMemberLookup
//
// Consumers who genuinely want passthrough ergonomics author a domain-
// specific wrapper struct with its own @dynamicMemberLookup annotation,
// forwarding to the underlying Tagged value.

@dynamicMemberLookup
struct Account {
    let storage: Tagged<User, Profile>

    subscript<U>(dynamicMember keyPath: KeyPath<Profile, U>) -> U {
        storage.rawValue[keyPath: keyPath]
    }
}

let wrapped = Account(storage: taggedUser)

precondition(wrapped.name == "Alice", "wrapper @dynamicMemberLookup forwards to Profile")
precondition(wrapped.age == 30,        "wrapper @dynamicMemberLookup forwards to Profile")
precondition(wrapped.city == "Paris",  "wrapper @dynamicMemberLookup forwards to Profile")

print("tagged-no-dynamicmemberlookup: consumer-side @dynamicMemberLookup wrapper provides passthrough ergonomics if domain wants it.")

// MARK: - Final summary

print("""

Empirical findings:
- Tagged itself does NOT have @dynamicMemberLookup; tagged.someProperty
  does NOT compile when 'someProperty' is on RawValue.
- @dynamicMemberLookup is a type-declaration-level attribute; it cannot
  be added retroactively via extension. Therefore SLI opt-in is structurally
  not authorable for this case.
- Explicit .rawValue access (recommended): every dot-access marks the
  type-boundary crossing.
- Consumer-side wrapper with own @dynamicMemberLookup: works for domain
  types that genuinely want passthrough ergonomics.

Classification: HARD absence. Not authorable in any opt-in form on Tagged
itself. Consumer's choice: explicit .rawValue access (preferred for
type-boundary visibility) OR domain-specific @dynamicMemberLookup wrapper
(when passthrough ergonomics are explicitly desired).
""")
