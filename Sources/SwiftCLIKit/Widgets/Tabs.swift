// Tabs.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Foundation

/// A tab bar widget that renders a row of selectable tabs with an active indicator.
///
/// ```swift
/// let tabs = Tabs(titles: ["Home", "Settings", "About"], activeIndex: 1)
/// tabs.render(into: &frame)
/// ```
public struct Tabs: Sendable {
    /// The tab titles.
    public var titles: [String]
    /// The index of the active tab.
    public var activeIndex: Int
    /// The style for the active tab.
    public var activeStyle: CellStyle
    /// The style for inactive tabs.
    public var inactiveStyle: CellStyle
    /// The separator string between tabs.
    public var separator: String
    /// An optional underline character drawn below the active tab.
    public var underline: Character?

    /// Creates a tabs widget.
    /// - Parameters:
    ///   - titles: The tab titles.
    ///   - activeIndex: The active tab index (default: 0).
    ///   - activeStyle: Style for the active tab (default: bold).
    ///   - inactiveStyle: Style for inactive tabs (default: default style).
    ///   - separator: Separator between tabs (default: " | ").
    ///   - underline: Optional underline character for the active tab.
    public init(
        titles: [String],
        activeIndex: Int = 0,
        activeStyle: CellStyle = CellStyle(attributes: [.bold]),
        inactiveStyle: CellStyle = CellStyle(),
        separator: String = " | ",
        underline: Character? = nil
    ) {
        self.titles = titles
        self.activeIndex = activeIndex
        self.activeStyle = activeStyle
        self.inactiveStyle = inactiveStyle
        self.separator = separator
        self.underline = underline
    }

    /// Renders this tab bar into the given frame.
    ///
    /// - Parameter frame: The frame to render into.
    public func render(into frame: inout Frame) {
        guard !titles.isEmpty else { return }

        var col = 0
        for (index, title) in titles.enumerated() {
            // Insert separator before all tabs except the first
            if index > 0 {
                let style = inactiveStyle
                frame.writeText(
                    separator,
                    x: col, y: 0,
                    fg: style.fg, bg: style.bg, attributes: style.attributes
                )
                col += separator.count
            }

            let isActive = index == activeIndex
            let style = isActive ? activeStyle : inactiveStyle
            let startCol = col

            frame.writeText(
                title,
                x: col, y: 0,
                fg: style.fg, bg: style.bg, attributes: style.attributes
            )
            col += title.count

            // Draw underline below the active tab if configured
            if isActive, let underlineChar = underline, frame.rect.height > 1 {
                for ux in startCol..<col {
                    frame.setCell(
                        x: ux, y: 1,
                        cell: Cell(
                            character: underlineChar,
                            fg: style.fg, bg: style.bg, attributes: style.attributes
                        )
                    )
                }
            }
        }
    }
}
