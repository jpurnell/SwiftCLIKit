// Sparkline.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Foundation

/// A sparkline widget that renders a series of data points as a miniature bar chart using braille or block characters.
///
/// ```swift
/// let spark = Sparkline(data: [1.0, 3.0, 2.0, 5.0, 4.0])
/// spark.render(into: &frame)
/// ```
public struct Sparkline: Sendable {
    /// The data points to display.
    public var data: [Double]
    /// The style for the sparkline.
    public var style: CellStyle
    /// An optional maximum value for scaling. When `nil`, the maximum data value is used.
    public var max: Double?

    /// Creates a sparkline widget.
    /// - Parameters:
    ///   - data: The data points.
    ///   - style: The sparkline style (default: default style).
    ///   - max: Optional maximum value for scaling.
    public init(
        data: [Double],
        style: CellStyle = CellStyle(),
        max: Double? = nil
    ) {
        self.data = data
        self.style = style
        self.max = max
    }

    /// Renders this sparkline into the given frame.
    ///
    /// - Parameter frame: The frame to render into.
    public func render(into frame: inout Frame) {
        guard !data.isEmpty else { return }

        let maxVal = self.max ?? data.max() ?? 1.0
        guard maxVal > 0 else { return }

        let blocks: [Character] = [" ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
        let frameWidth = frame.rect.width
        let frameHeight = frame.rect.height
        let columnCount = Swift.min(data.count, frameWidth)

        for col in 0..<columnCount {
            let value = Swift.max(data[col], 0.0)
            let ratio = Swift.min(value / maxVal, 1.0)
            let scaledHeight = ratio * Double(frameHeight)
            let fullBlocks = Int(scaledHeight)
            let remainder = scaledHeight - Double(fullBlocks)
            let partialIndex = Int(remainder * 8.0)

            // Draw full blocks from bottom up
            for row in 0..<fullBlocks {
                let y = frameHeight - 1 - row
                guard y >= 0 else { break }
                frame.setCell(x: col, y: y, cell: Cell(
                    character: "█",
                    fg: style.fg,
                    bg: style.bg,
                    attributes: style.attributes
                ))
            }

            // Draw partial block above the full blocks
            if partialIndex > 0 {
                let y = frameHeight - 1 - fullBlocks
                guard y >= 0 else { continue }
                frame.setCell(x: col, y: y, cell: Cell(
                    character: blocks[partialIndex],
                    fg: style.fg,
                    bg: style.bg,
                    attributes: style.attributes
                ))
            }
        }
    }
}
