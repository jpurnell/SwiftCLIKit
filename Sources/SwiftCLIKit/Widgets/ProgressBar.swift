// ProgressBar.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Foundation

/// A progress bar widget that displays current/total progress with an optional percentage label.
///
/// ```swift
/// let bar = ProgressBar(current: 7, total: 10, showPercentage: true)
/// bar.render(into: &frame)
/// ```
public struct ProgressBar: Sendable {
    /// The current progress value.
    public var current: Double
    /// The total (maximum) progress value.
    public var total: Double
    /// The style for the progress bar.
    public var style: CellStyle
    /// Whether to display the percentage text.
    public var showPercentage: Bool

    /// Creates a progress bar widget.
    /// - Parameters:
    ///   - current: The current progress value.
    ///   - total: The total progress value.
    ///   - style: The bar style (default: default style).
    ///   - showPercentage: Whether to show percentage text (default: true).
    public init(
        current: Double,
        total: Double,
        style: CellStyle = CellStyle(),
        showPercentage: Bool = true
    ) {
        self.current = current
        self.total = total
        self.style = style
        self.showPercentage = showPercentage
    }

    /// Renders this progress bar into the given frame.
    ///
    /// - Parameter frame: The frame to render into.
    public func render(into frame: inout Frame) {
        guard total > 0 else {
            // Division safety: render "0%" or empty bar for zero total
            if showPercentage {
                frame.writeText("0%", x: 0, y: 0)
            }
            return
        }

        let ratio = Swift.min(Swift.max(Double(current) / Double(total), 0.0), 1.0)
        let label: String? = showPercentage ? "\(Int(ratio * 100))%" : nil

        let gauge = Gauge(
            ratio: ratio,
            label: label,
            filledStyle: style,
            unfilledStyle: style
        )
        gauge.render(into: &frame)
    }
}
