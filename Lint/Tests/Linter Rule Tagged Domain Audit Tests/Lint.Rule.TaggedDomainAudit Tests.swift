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

import Linter_Primitives
import Linter_Rules_Test_Support
import SwiftParser
import SwiftSyntax
import Testing

@testable import Linter_Rule_Tagged_Domain_Audit

extension Lint.Rule {
    @Suite
    struct `tagged unchecked with typed alternative Tests` {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

extension Lint.Rule.`tagged unchecked with typed alternative Tests` {
    static func findings(
        in source: Swift.String,
        file: Swift.String = "test.swift"
    ) -> [Diagnostic.Record] {
        let parsed = Lint.Source.parsed(from: source, file: file)
        return Lint.Rule.`tagged unchecked with typed alternative`.findings(parsed, .warning)
    }
}

extension Lint.Rule.`tagged unchecked with typed alternative Tests`.Unit {
    @Test
    func `Tagged generic-specialized with _unchecked is flagged`() {
        let source = "let x = Tagged<Tag, Int>(_unchecked: 42)"
        let findings = Lint.Rule.`tagged unchecked with typed alternative Tests`.findings(
            in: source
        )
        let count = findings.count
        #expect(count == 1)
        if count == 1 {
            #expect(findings[0].identifier == "tagged unchecked with typed alternative")
            #expect(findings[0].severity == .warning)
        }
    }

    @Test
    func `Tagged bare with _unchecked is flagged`() {
        let source = """
            let value: Tagged<Tag, Int> = Tagged(_unchecked: 7)
            _ = value
            """
        let findings = Lint.Rule.`tagged unchecked with typed alternative Tests`.findings(
            in: source
        )
        #expect(findings.count == 1)
    }

    @Test
    func `module-qualified Tagged with _unchecked is flagged`() {
        let source = "let id = Tagged_Primitives.Tagged(_unchecked: 0)"
        let findings = Lint.Rule.`tagged unchecked with typed alternative Tests`.findings(
            in: source
        )
        #expect(findings.count == 1)
    }

    @Test
    func `multiple Tagged _unchecked sites are all flagged`() {
        let source = """
            let a = Tagged<TagA, Int>(_unchecked: 1)
            let b = Tagged<TagB, Int>(_unchecked: 2)
            let c = Tagged<TagC, Int>(_unchecked: 3)
            """
        let findings = Lint.Rule.`tagged unchecked with typed alternative Tests`.findings(
            in: source
        )
        #expect(findings.count == 3)
    }
}

extension Lint.Rule.`tagged unchecked with typed alternative Tests`.`Edge Case` {
    @Test
    func `Tagged without _unchecked is NOT flagged`() {
        let source = "let x: Tagged<Tag, Int> = 42"
        let findings = Lint.Rule.`tagged unchecked with typed alternative Tests`.findings(
            in: source
        )
        #expect(findings.isEmpty)
    }

    @Test
    func `non-Tagged callee with _unchecked is NOT flagged`() {
        let source = "let x = OtherWrapper(_unchecked: 0)"
        let findings = Lint.Rule.`tagged unchecked with typed alternative Tests`.findings(
            in: source
        )
        #expect(findings.isEmpty)
    }

    @Test
    func `self init with _unchecked inside Tagged extension is NOT flagged`() {
        let source = """
            extension Tagged {
                init(other: Underlying) {
                    self.init(_unchecked: other)
                }
            }
            """
        let findings = Lint.Rule.`tagged unchecked with typed alternative Tests`.findings(
            in: source
        )
        #expect(findings.isEmpty)
    }

    @Test
    func `Tagged with double-underscore __unchecked is NOT flagged`() {
        let source = "let x = Tagged<Tag, Int>(__unchecked: 42)"
        let findings = Lint.Rule.`tagged unchecked with typed alternative Tests`.findings(
            in: source
        )
        #expect(findings.isEmpty)
    }

    @Test
    func `empty file produces no findings`() {
        let findings = Lint.Rule.`tagged unchecked with typed alternative Tests`.findings(in: "")
        #expect(findings.isEmpty)
    }

    @Test
    func `_unchecked in a string literal is NOT flagged`() {
        let source = "let s = \"Tagged<X, Y>(_unchecked: 0)\""
        let findings = Lint.Rule.`tagged unchecked with typed alternative Tests`.findings(
            in: source
        )
        #expect(findings.isEmpty)
    }

    @Test
    func `Tagged with _unchecked inside @Test function is NOT flagged`() {
        let source = """
            @Test
            func someBehavior() {
                let x = Tagged<Tag, Int>(_unchecked: 42)
                _ = x
            }
            """
        let findings = Lint.Rule.`tagged unchecked with typed alternative Tests`.findings(
            in: source
        )
        #expect(findings.isEmpty)
    }

    @Test
    func `Tagged with _unchecked inside non-@Test function is flagged`() {
        let source = """
            func someBehavior() {
                let x = Tagged<Tag, Int>(_unchecked: 42)
                _ = x
            }
            """
        let findings = Lint.Rule.`tagged unchecked with typed alternative Tests`.findings(
            in: source
        )
        #expect(findings.count == 1)
    }

    @Test
    func `Tagged with _unchecked inside @Test function with module qualifier is NOT flagged`() {
        let source = """
            @Testing.Test
            func someBehavior() {
                let x = Tagged<Tag, Int>(_unchecked: 42)
                _ = x
            }
            """
        let findings = Lint.Rule.`tagged unchecked with typed alternative Tests`.findings(
            in: source
        )
        #expect(findings.isEmpty)
    }
}
