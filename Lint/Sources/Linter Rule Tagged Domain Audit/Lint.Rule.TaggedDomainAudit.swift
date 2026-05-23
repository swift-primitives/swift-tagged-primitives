// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-tagged-primitives open source project
//
// Copyright (c) 2026 Coen ten Thije Boonkkamp and the swift-tagged-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Linter_Primitives
internal import SwiftSyntax
internal import Tagged_Primitives

/// PoC custom rule with a domain-aware predicate.
///
/// Citation: PoC of Lint/ nested-package mechanism with domain-aware
/// predicate (architecture cohort Phase A —
/// `HANDOFF-architecture-poc-lint-nested-package.md`).
///
/// The rule flags `Tagged<…>(_unchecked: …)` construction sites in
/// the consumer's source. `_unchecked` bypasses the typed-init
/// alternatives that `swift-tagged-primitives`'s standard-library-
/// integration target ships (e.g., `ExpressibleByIntegerLiteral`,
/// `ExpressibleByStringLiteral`); when one of those typed inits
/// fits, the typed form is preferred because the underlying value
/// is then validated by the literal-protocol's lower-bound contract
/// rather than trusted unchecked.
///
/// AST shape: a `FunctionCallExprSyntax` whose callee identifier
/// resolves to `Tagged` (bare, generic-specialized, or member-
/// accessed) and whose arguments include one labeled `_unchecked`.
///
/// Domain awareness: the rule imports `Tagged_Primitives` and
/// references `Tagged.self` at the type level (see
/// `namingTaggedDomainAuditAnchor`). The Lint/ nested-package
/// mechanism is validated end-to-end iff this rule compiles and runs
/// alongside the institute's hierarchical rule packs in the Lint
/// executable.
extension Lint.Rule {
    public static let `tagged unchecked with typed alternative` = Lint.Rule(
        id: "tagged unchecked with typed alternative",
        default: .warning,
        findings: { source, severity in
            let visitor = TaggedDomainAuditVisitor(
                source: source.file,
                severity: severity,
                converter: source.converter
            )
            visitor.walk(source.tree)
            return visitor.matches
        }
    )
}

@usableFromInline
internal let taggedDomainAuditMessage: Swift.String =
    "[tagged unchecked with typed alternative] PoC domain-aware rule: "
    + "`Tagged<…>(_unchecked: …)` bypasses tagged-primitives' typed-init alternatives "
    + "(ExpressibleBy*Literal conformances in the Standard Library Integration target). "
    + "Prefer a literal-typed init when the underlying type's literal protocol fits; "
    + "reach for `_unchecked` only when the underlying value is already validated upstream "
    + "and a typed init is genuinely unavailable. This rule is the PoC's domain-aware "
    + "predicate validating the Lint/ nested-package mechanism (architecture cohort Phase A)."

/// Functions whose `_unchecked:` use is structurally authorized — the
/// underlying value is either opaque-by-construction (transform-closure
/// output) or validated by an upstream Tagged construction invariant
/// (phantom-tag swap). Inside these contexts, the rule's "prefer a typed
/// init" advice cannot apply because no typed init exists for the
/// opaque or already-validated value.
///
/// Detection: walk up from the call site to the enclosing function
/// decl; if its name matches an entry, exempt the use.
@usableFromInline
internal let taggedDomainAuditExemptOperations: [Swift.String: Swift.String] = [
    "map":   "preserve-shape transform; closure output is opaque-by-construction",
    "retag": "phantom-tag swap; underlying validated upstream by Tagged construction invariant",
]

/// Attribute names whose presence on the enclosing function decl exempts
/// the `_unchecked:` use. Currently `@Test` (swift-testing): a test
/// function legitimately exercises the full API surface including
/// `_unchecked` — for example, when Underlying is `~Copyable` (literal
/// init structurally cannot fit), when the test directly compares
/// literal-init against the canonical `_unchecked` form, or when
/// performance hot-path tests measure the barest construction.
///
/// Detection: walk up from the call site to the enclosing function
/// decl; check the decl's attribute list for one of these names.
///
/// Same intuition as `[RULE-EXEMPT-4]` (extension-pattern attribute):
/// the attribute marks the function as belonging to a domain where the
/// rule's recommendation does not apply.
@usableFromInline
internal let taggedDomainAuditExemptAttributes: [Swift.String: Swift.String] = [
    "Test": "swift-testing test function; tests exercise the full API surface including _unchecked",
]

/// Domain anchor — references `Tagged_Primitives.Tagged` at the type
/// level so the `Tagged_Primitives` import is load-bearing at compile
/// time. This is the structural proof that the Lint/ nested-package
/// mechanism actually links the consumer's domain dep into the rule's
/// compile graph; without it the import would be elidable and the
/// mechanism would not be validated. The anchor is not consulted by
/// the predicate.
@usableFromInline
internal let taggedDomainAuditAnchor: Any.Type = Tagged<Swift.Int, Swift.Int>.self

internal final class TaggedDomainAuditVisitor: SyntaxVisitor {
    let source: Source.File
    let severity: Diagnostic.Severity
    let converter: SourceLocationConverter
    var matches: [Diagnostic.Record] = []

    init(
        source: Source.File,
        severity: Diagnostic.Severity,
        converter: SourceLocationConverter
    ) {
        self.source = source
        self.severity = severity
        self.converter = converter
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard Self.calleeIsTagged(node.calledExpression) else {
            return .visitChildren
        }
        // Exempt enclosing-function contexts (function-name or attribute):
        // - preserve-shape transforms (`map`, `retag`) per
        //   `taggedDomainAuditExemptOperations` — opaque-by-construction
        //   or validated-upstream cases
        // - `@Test`-attributed test functions per
        //   `taggedDomainAuditExemptAttributes` — tests exercise the full
        //   API surface including `_unchecked`
        if Self.isInsideExemptOperation(Syntax(node)) {
            return .visitChildren
        }
        for argument in node.arguments {
            guard
                let label = argument.label,
                label.tokenKind == .identifier("_unchecked")
            else { continue }
            let location = converter.location(
                for: argument.positionAfterSkippingLeadingTrivia
            )
            matches.append(
                Diagnostic.Record(
                    location: Source.Location(
                        fileID: source.fileID,
                        filePath: source.filePath,
                        line: location.line,
                        column: location.column
                    ),
                    severity: severity,
                    identifier: "tagged unchecked with typed alternative",
                    message: taggedDomainAuditMessage
                )
            )
            break  // one finding per call site
        }
        return .visitChildren
    }

    private static func isInsideExemptOperation(_ node: Syntax) -> Swift.Bool {
        var current: Syntax? = node.parent
        while let candidate = current {
            if let fn = candidate.as(FunctionDeclSyntax.self) {
                if taggedDomainAuditExemptOperations[fn.name.text] != nil {
                    return true
                }
                if Self.hasExemptAttribute(fn.attributes) {
                    return true
                }
                return false
            }
            current = candidate.parent
        }
        return false
    }

    private static func hasExemptAttribute(_ attributes: AttributeListSyntax) -> Swift.Bool {
        for element in attributes {
            guard case let .attribute(attribute) = element else { continue }
            let name: Swift.String
            if let ident = attribute.attributeName.as(IdentifierTypeSyntax.self) {
                name = ident.name.text
            } else if let member = attribute.attributeName.as(MemberTypeSyntax.self) {
                name = member.name.text
            } else {
                continue
            }
            if taggedDomainAuditExemptAttributes[name] != nil {
                return true
            }
        }
        return false
    }

    /// Domain-narrowing: the rule fires only when the call's callee
    /// identifier is `Tagged` (bare, generic-specialized, or
    /// member-accessed). Non-Tagged `_unchecked:` call sites are out
    /// of scope.
    private static func calleeIsTagged(_ expression: ExprSyntax) -> Bool {
        if let decl = expression.as(DeclReferenceExprSyntax.self) {
            return decl.baseName.text == "Tagged"
        }
        if let generic = expression.as(GenericSpecializationExprSyntax.self) {
            return calleeIsTagged(generic.expression)
        }
        if let member = expression.as(MemberAccessExprSyntax.self) {
            return member.declName.baseName.text == "Tagged"
        }
        return false
    }
}
