// BarChart.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Foundation

/// A vertical bar chart widget that renders labeled bars with proportional heights.
///
/// ```swift
/// let chart = BarChart(bars: [
///     BarChart.Bar(label: "A", value: 10),
///     BarChart.Bar(label: "B", value: 20),
///     BarChart.Bar(label: "C", value: 15),
/// ])
/// chart.render(into: &frame)
/// ```
public struct BarChart: Sendable {
    /// A single bar in a ``BarChart`` widget.
    public struct Bar: Sendable, Equatable {
        /// The label displayed below the bar.
        public var label: String
        /// The numeric value determining bar height.
        public var value: Double
        /// The style for this bar.
        public var style: CellStyle

        /// Creates a bar.
        /// - Parameters:
        ///   - label: The label text.
        ///   - value: The numeric value.
        ///   - style: The bar style (default: default style).
        public init(label: String, value: Double, style: CellStyle = CellStyle()) {
            self.label = label
            self.value = value
            self.style = style
        }
    }

    /// The bars to display.
    public var bars: [Bar]
    /// The width of each bar in columns.
    public var barWidth: Int
    /// The gap between bars in columns.
    public var barGap: Int
    /// An optional maximum value for scaling. When `nil`, the maximum bar value is used.
    public var max: Double?
    /// Whether to display the numeric value above each bar.
    public var showValues: Bool

    /// Creates a bar chart widget.
    /// - Parameters:
    ///   - bars: The bars to display.
    ///   - barWidth: The width of each bar (default: 3).
    ///   - barGap: The gap between bars (default: 1).
    ///   - max: Optional maximum value for scaling.
    ///   - showValues: Whether to show values above bars (default: false).
    public init(
        bars: [Bar],
        barWidth: Int = 3,
        barGap: Int = 1,
        max: Double? = nil,
        showValues: Bool = false
    ) {
        self.bars = bars
        self.barWidth = barWidth
        self.barGap = barGap
        self.max = max
        self.showValues = showValues
    }

    /// Renders this bar chart into the given frame.
    ///
    /// - Parameter frame: The frame to render into.
    public func render(into frame: inout Frame) {
        guard !bars.isEmpty else { return }

        let frameWidth = frame.rect.width
        let frameHeight = frame.rect.height
        guard frameHeight > 1 else { return }

        let labelRowCount = 1
        let valueRowCount = showValues ? 1 : 0
        let chartHeight = frameHeight - labelRowCount - valueRowCount
        guard chartHeight > 0 else { return }

        let maxVal = self.max ?? bars.max(by: { $0.value < $1.value })?.value ?? 1.0
        guard maxVal > 0 else {
            // Division safety: all values zero, just draw labels
            for (i, bar) in bars.enumerated() {
                let xOffset = i * (barWidth + barGap)
                let labelX = xOffset + Swift.max((barWidth - bar.label.count) / 2, 0)
                let labelY = frameHeight - 1
                guard labelX < frameWidth else { continue }
                frame.writeText(bar.label, x: labelX, y: labelY)
            }
            return
        }

        for (i, bar) in bars.enumerated() {
            let xOffset = i * (barWidth + barGap)
            guard xOffset < frameWidth else { break }

            let ratio = Swift.min(Swift.max(bar.value / maxVal, 0.0), 1.0)
            let barHeight = Int(ratio * Double(chartHeight))

            // Draw bar columns from bottom of chart area upward
            for row in 0..<barHeight {
                let y = frameHeight - 1 - labelRowCount - row
                guard y >= 0 else { break }
                for col in 0..<barWidth {
                    let x = xOffset + col
                    guard x < frameWidth else { break }
                    frame.setCell(x: x, y: y, cell: Cell(
                        character: "█",
                        fg: bar.style.fg,
                        bg: bar.style.bg,
                        attributes: bar.style.attributes
                    ))
                }
            }

            // Draw value above bar if showValues
            if showValues {
                let valueStr = String(Int(bar.value))
                let valueX = xOffset + Swift.max((barWidth - valueStr.count) / 2, 0)
                let valueY = frameHeight - 1 - labelRowCount - barHeight
                guard valueY >= 0 else { continue }
                frame.writeText(valueStr, x: valueX, y: valueY)
            }

            // Draw label centered at bottom row
            let labelX = xOffset + Swift.max((barWidth - bar.label.count) / 2, 0)
            let labelY = frameHeight - 1
            guard labelX < frameWidth else { continue }
            frame.writeText(bar.label, x: labelX, y: labelY)
        }
    }
}
