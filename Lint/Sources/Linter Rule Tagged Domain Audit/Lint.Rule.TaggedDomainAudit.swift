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
        // Preserve-shape exemption: inside `static func map` or `static
        // func retag` (and instance equivalents), the `_unchecked:` use
        // is structurally authorized — transform output is opaque or
        // the underlying is validated upstream. The rule's own docstring
        // explicitly authorizes this case; the amendment makes it
        // mechanically enforceable.
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
                return false
            }
            current = candidate.parent
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
