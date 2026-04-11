//
//  BufferRef.swift
//  SwiftCLIKit
//
//  Created by Justin Purnell on 2026-04-10.
//

import Foundation

/// Reference-type wrapper around a ``CellBuffer`` so that multiple ``Frame``
/// instances can share and mutate the same underlying storage.
///
/// `Frame` uses `BufferRef` internally so that sub-frames created via
/// ``Frame/subFrame(_:)`` write into the same buffer as their parent.
public final class BufferRef: @unchecked Sendable {
    // Justification: Frame is always used on a single thread within a render pass

    /// The underlying cell buffer.
    public var buffer: CellBuffer

    /// Creates a reference wrapping the given buffer.
    public init(_ buffer: CellBuffer) {
        self.buffer = buffer
    }
}
