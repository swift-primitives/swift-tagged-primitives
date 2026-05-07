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

import Testing
import SwiftSyntax
import SwiftParser
import Linter_Primitives
@testable import Linter_Rule_Tagged_Domain_Audit

extension Lint.Rule.TaggedDomainAudit {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

extension Lint.Rule.TaggedDomainAudit.Test {
    static func findings(
        in source: Swift.String,
        file: Swift.String = "test.swift"
    ) -> [Lint.Finding] {
        let tree = Parser.parse(source: source)
        let converter = SourceLocationConverter(fileName: file, tree: tree)
        var manager = Source.Manager()
        let id = manager.register(
            fileID: file,
            filePath: file,
            content: Swift.Array(source.utf8)
        )
        let parsed = Lint.Source.Parsed(
            file: manager.file(for: id),
            tree: tree,
            converter: converter
        )
        return Lint.Rule.TaggedDomainAudit().findings(in: parsed)
    }
}

// MARK: - Positive cases (rule fires)

extension Lint.Rule.TaggedDomainAudit.Test.Unit {
    @Test
    func `Tagged generic-specialized with _unchecked is flagged`() {
        let source = "let x = Tagged<Tag, Int>(_unchecked: 42)"
        let findings = Lint.Rule.TaggedDomainAudit.Test.findings(in: source)
        let count = findings.count
        #expect(count == 1)
        if count == 1 {
            #expect(findings[0].identifier == "tagged_unchecked_with_typed_alternative")
            #expect(findings[0].severity == .warning)
        }
    }

    @Test
    func `Tagged bare with _unchecked is flagged`() {
        let source = """
        let value: Tagged<Tag, Int> = Tagged(_unchecked: 7)
        _ = value
        """
        let findings = Lint.Rule.TaggedDomainAudit.Test.findings(in: source)
        #expect(findings.count == 1)
    }

    @Test
    func `module-qualified Tagged with _unchecked is flagged`() {
        let source = "let id = Tagged_Primitives.Tagged(_unchecked: 0)"
        let findings = Lint.Rule.TaggedDomainAudit.Test.findings(in: source)
        #expect(findings.count == 1)
    }

    @Test
    func `multiple Tagged _unchecked sites are all flagged`() {
        let source = """
        let a = Tagged<TagA, Int>(_unchecked: 1)
        let b = Tagged<TagB, Int>(_unchecked: 2)
        let c = Tagged<TagC, Int>(_unchecked: 3)
        """
        let findings = Lint.Rule.TaggedDomainAudit.Test.findings(in: source)
        #expect(findings.count == 3)
    }

    @Test
    func `custom severity is honored`() {
        let source = "let x = Tagged<Tag, Int>(_unchecked: 42)"
        let tree = Parser.parse(source: source)
        let converter = SourceLocationConverter(fileName: "test.swift", tree: tree)
        var manager = Source.Manager()
        let id = manager.register(
            fileID: "test.swift",
            filePath: "test.swift",
            content: Swift.Array(source.utf8)
        )
        let parsed = Lint.Source.Parsed(
            file: manager.file(for: id),
            tree: tree,
            converter: converter
        )
        let rule = Lint.Rule.TaggedDomainAudit(severity: .error)
        let findings = rule.findings(in: parsed)
        let count = findings.count
        #expect(count == 1)
        if count == 1 {
            #expect(findings[0].severity == .error)
        }
    }
}

// MARK: - Negative cases (rule does not fire)

extension Lint.Rule.TaggedDomainAudit.Test.`Edge Case` {
    @Test
    func `Tagged without _unchecked is NOT flagged`() {
        let source = "let x: Tagged<Tag, Int> = 42"
        let findings = Lint.Rule.TaggedDomainAudit.Test.findings(in: source)
        #expect(findings.isEmpty)
    }

    @Test
    func `non-Tagged callee with _unchecked is NOT flagged`() {
        // _unchecked: label on a non-Tagged callee — outside the rule's
        // domain narrowing, so no finding.
        let source = "let x = OtherWrapper(_unchecked: 0)"
        let findings = Lint.Rule.TaggedDomainAudit.Test.findings(in: source)
        #expect(findings.isEmpty)
    }

    @Test
    func `self init with _unchecked inside Tagged extension is NOT flagged`() {
        // The callee is `self.init`, not `Tagged`, so the rule's domain
        // narrowing skips it. This deliberately avoids flagging the
        // legitimate internal `_unchecked` init delegation that lives
        // inside Tagged's own implementation files.
        let source = """
        extension Tagged {
            init(other: Underlying) {
                self.init(_unchecked: other)
            }
        }
        """
        let findings = Lint.Rule.TaggedDomainAudit.Test.findings(in: source)
        #expect(findings.isEmpty)
    }

    @Test
    func `Tagged with double-underscore __unchecked is NOT flagged`() {
        // `__unchecked` (double underscore) is the institute's R5 label,
        // distinct from Tagged's `_unchecked` (single underscore).
        let source = "let x = Tagged<Tag, Int>(__unchecked: 42)"
        let findings = Lint.Rule.TaggedDomainAudit.Test.findings(in: source)
        #expect(findings.isEmpty)
    }

    @Test
    func `empty file produces no findings`() {
        let findings = Lint.Rule.TaggedDomainAudit.Test.findings(in: "")
        #expect(findings.isEmpty)
    }

    @Test
    func `_unchecked in a string literal is NOT flagged`() {
        let source = "let s = \"Tagged<X, Y>(_unchecked: 0)\""
        let findings = Lint.Rule.TaggedDomainAudit.Test.findings(in: source)
        #expect(findings.isEmpty)
    }
}
