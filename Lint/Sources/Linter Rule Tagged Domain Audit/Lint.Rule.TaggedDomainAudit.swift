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
/// The rule's domain awareness: it imports `Tagged_Primitives` and
/// references `Tagged.self` at the type level (see
/// ``Lint/Rule/TaggedDomainAudit/_domainAnchor``). The Lint/ nested-
/// package mechanism is validated end-to-end iff this rule compiles
/// and runs alongside the institute's built-in rule packs in the
/// Lint executable.
extension Lint.Rule {
    public struct TaggedDomainAudit: Lint.Rule.`Protocol` {
        public static let id: Lint.Rule.ID = "tagged_unchecked_with_typed_alternative"
        public static let defaultSeverity: Diagnostic.Severity = .warning

        public let severity: Diagnostic.Severity

        @inlinable
        public init(severity: Diagnostic.Severity = .warning) {
            self.severity = severity
        }

        public func findings(in source: Lint.Source.Parsed) -> [Lint.Finding] {
            let visitor = Visitor(
                source: source.file,
                severity: severity,
                converter: source.converter
            )
            visitor.walk(source.tree)
            return visitor.matches
        }
    }
}

extension Lint.Rule.TaggedDomainAudit {
    @usableFromInline
    static let message: Swift.String =
        "[tagged_unchecked_with_typed_alternative] PoC domain-aware rule: "
        + "`Tagged<…>(_unchecked: …)` bypasses tagged-primitives' typed-init alternatives "
        + "(ExpressibleBy*Literal conformances in the Standard Library Integration target). "
        + "Prefer a literal-typed init when the underlying type's literal protocol fits; "
        + "reach for `_unchecked` only when the underlying value is already validated upstream "
        + "and a typed init is genuinely unavailable. This rule is the PoC's domain-aware "
        + "predicate validating the Lint/ nested-package mechanism (architecture cohort Phase A)."

    /// Domain anchor — references `Tagged_Primitives.Tagged` at the
    /// type level so the `Tagged_Primitives` import is load-bearing
    /// at compile time. This is the structural proof that the
    /// Lint/ nested-package mechanism actually links the consumer's
    /// domain dep into the rule's compile graph; without it the
    /// import would be elidable and the mechanism would not be
    /// validated. The anchor is not consulted by the predicate.
    @usableFromInline
    static let _domainAnchor: Any.Type = Tagged<Swift.Int, Swift.Int>.self

    final class Visitor: SyntaxVisitor {
        let source: Source.File
        let severity: Diagnostic.Severity
        let converter: SourceLocationConverter
        var matches: [Lint.Finding] = []

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
            for argument in node.arguments {
                guard
                    let label = argument.label,
                    label.tokenKind == .identifier("_unchecked")
                else { continue }
                let location = converter.location(
                    for: argument.positionAfterSkippingLeadingTrivia
                )
                matches.append(
                    Lint.Finding(
                        location: Source.Location(
                            fileID: source.fileID,
                            filePath: source.filePath,
                            line: location.line,
                            column: location.column
                        ),
                        severity: severity,
                        identifier: Lint.Rule.TaggedDomainAudit.id.underlying,
                        message: Lint.Rule.TaggedDomainAudit.message
                    )
                )
                break  // one finding per call site
            }
            return .visitChildren
        }

        /// Domain-narrowing: the rule fires only when the call's
        /// callee identifier is `Tagged` (bare, generic-specialized,
        /// or member-accessed). This is the rule's domain-aware
        /// predicate — non-Tagged `_unchecked:` call sites are out of
        /// scope.
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
}
