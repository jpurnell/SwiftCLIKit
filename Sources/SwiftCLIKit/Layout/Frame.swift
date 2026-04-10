// Frame.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Foundation

/// A rendering surface backed by a ``CellBuffer`` and scoped to a ``Rect``.
///
/// `Frame` provides an immediate-mode rendering API. Widgets write into a frame,
/// and the caller extracts the underlying buffer via ``cellBuffer`` when done.
///
/// ```swift
/// var frame = Frame(buffer: CellBuffer(width: 80, height: 24),
///                   rect: Rect(x: 0, y: 0, width: 80, height: 24))
/// frame.setCell(x: 5, y: 3, cell: Cell(character: "X"))
/// let finalBuffer = frame.cellBuffer
/// ```
public struct Frame: Sendable {
    /// The rectangular region this frame covers.
    public let rect: Rect
    private var buffer: CellBuffer  // owned copy for Sendable compliance

    /// Creates a frame backed by the given buffer and scoped to the given rect.
    /// - Parameters:
    ///   - buffer: The cell buffer to render into.
    ///   - rect: The region of the buffer this frame covers.
    public init(buffer: CellBuffer, rect: Rect) {
        self.buffer = buffer
        self.rect = rect
    }

    /// Sets a single cell at the given position (relative to the frame's rect).
    ///
    /// Coordinates are translated to absolute buffer positions. Writes outside
    /// the frame's rect are silently ignored.
    /// - Parameters:
    ///   - x: Column offset within the frame.
    ///   - y: Row offset within the frame.
    ///   - cell: The cell value to write.
    public mutating func setCell(x: Int, y: Int, cell: Cell) {
        let absX = rect.x + x
        let absY = rect.y + y
        guard rect.contains(x: absX, y: absY) else { return }
        buffer[absX, absY] = cell
    }

    /// Writes text horizontally starting at the given position (relative to the frame's rect).
    ///
    /// Characters that fall outside the frame's rect are skipped. Wide characters
    /// (CJK, emoji) consume two columns; a continuation space is written in the
    /// second column when the character fits.
    /// - Parameters:
    ///   - text: The string to render.
    ///   - x: Starting column offset within the frame.
    ///   - y: Row offset within the frame.
    ///   - fg: Foreground color for each character.
    ///   - bg: Background color for each character.
    ///   - attributes: Text styling attributes for each character.
    public mutating func writeText(
        _ text: String,
        x: Int,
        y: Int,
        fg: Color = .default,
        bg: Color = .default,
        attributes: CellAttributes = []
    ) {
        var col = x
        for ch in text {
            let absX = rect.x + col
            let absY = rect.y + y
            guard rect.contains(x: absX, y: absY) else {
                let charWidth = UnicodeWidth.width(of: ch)
                if charWidth == 2 {
                    col += 2
                } else {
                    col += Swift.max(charWidth, 1)
                }
                continue
            }
            let charWidth = UnicodeWidth.width(of: ch)
            buffer[absX, absY] = Cell(character: ch, fg: fg, bg: bg, attributes: attributes)
            if charWidth == 2 {
                let nextX = absX + 1
                if rect.contains(x: nextX, y: absY) {
                    buffer[nextX, absY] = Cell(character: " ", fg: fg, bg: bg, attributes: attributes)
                }
                col += 2
            } else {
                col += Swift.max(charWidth, 1)
            }
        }
    }

    /// Returns a sub-frame clipped to the intersection of this frame's rect and the given rect.
    ///
    /// If the two rectangles do not overlap, the returned frame has zero area and
    /// all writes into it are no-ops.
    /// - Parameter subRect: The desired sub-region in absolute buffer coordinates.
    /// - Returns: A new ``Frame`` scoped to the overlapping area.
    public func subFrame(_ subRect: Rect) -> Frame {
        guard let clipped = rect.intersection(subRect) else {
            return Frame(buffer: buffer, rect: Rect(x: 0, y: 0, width: 0, height: 0))
        }
        return Frame(buffer: buffer, rect: clipped)
    }

    /// The underlying buffer after rendering.
    ///
    /// Extract this after all widgets have rendered to pass the completed buffer
    /// to ``DiffRenderer/render(current:previous:)``.
    public var cellBuffer: CellBuffer { buffer }
}
