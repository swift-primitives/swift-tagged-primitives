// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

extension Tagged: CustomStringConvertible where Tag: ~Copyable & ~Escapable, Underlying: CustomStringConvertible & Escapable {
    /// Forwards to the underlying value's description.
    @inlinable
    public var description: String { underlying.description }
}
