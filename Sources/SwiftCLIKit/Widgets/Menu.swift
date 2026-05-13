// Menu.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Foundation

/// A menu widget that renders a vertical list of selectable items with optional key hints.
///
/// ```swift
/// let menu = Menu(
///     items: [
///         Menu.MenuItem(label: "New File", keyHint: "Ctrl+N"),
///         Menu.MenuItem(label: "Open...", keyHint: "Ctrl+O"),
///         Menu.MenuItem(label: "Disabled", enabled: false),
///     ],
///     selectedIndex: 0
/// )
/// menu.render(into: &frame)
/// ```
public struct Menu: Sendable {
    /// A single item in a ``Menu`` widget.
    public struct MenuItem: Sendable, Equatable {
        /// The label text.
        public var label: String
        /// An optional keyboard shortcut hint shown right-aligned.
        public var keyHint: String?
        /// Whether this item is selectable.
        public var enabled: Bool

        /// Creates a menu item.
        /// - Parameters:
        ///   - label: The label text.
        ///   - keyHint: Optional keyboard shortcut hint.
        ///   - enabled: Whether the item is selectable (default: true).
        public init(label: String, keyHint: String? = nil, enabled: Bool = true) {
            self.label = label
            self.keyHint = keyHint
            self.enabled = enabled
        }
    }

    /// The menu items.
    public var items: [MenuItem]
    /// The index of the currently selected item.
    public var selectedIndex: Int
    /// The style for the selected item.
    public var highlightStyle: CellStyle
    /// The style for disabled items.
    public var disabledStyle: CellStyle

    /// Creates a menu widget.
    /// - Parameters:
    ///   - items: The menu items.
    ///   - selectedIndex: The selected item index (default: 0).
    ///   - highlightStyle: Style for the selected item (default: reverse video).
    ///   - disabledStyle: Style for disabled items (default: dim).
    public init(
        items: [MenuItem],
        selectedIndex: Int = 0,
        highlightStyle: CellStyle = CellStyle(attributes: [.reverse]),
        disabledStyle: CellStyle = CellStyle(attributes: [.dim])
    ) {
        self.items = items
        self.selectedIndex = selectedIndex
        self.highlightStyle = highlightStyle
        self.disabledStyle = disabledStyle
    }

    /// Renders this menu into the given frame.
    /// - Parameter frame: The frame to render into.
    public func render(into frame: inout Frame) {
        guard frame.rect.width > 0, frame.rect.height > 0 else { return }
        guard !items.isEmpty else { return }

        let visibleCount = min(items.count, frame.rect.height)
        for rowIdx in 0..<visibleCount {
            let item = items[rowIdx]
            let isSelected = (rowIdx == selectedIndex)
            let style: CellStyle
            if !item.enabled {
                style = disabledStyle
            } else if isSelected {
                style = highlightStyle
            } else {
                style = CellStyle()
            }

            // Write label on the left
            frame.writeText(
                item.label,
                x: 0,
                y: rowIdx,
                fg: style.fg,
                bg: style.bg,
                attributes: style.attributes
            )

            // Write keyHint right-aligned
            if let hint = item.keyHint {
                let hintX = max(0, frame.rect.width - hint.count)
                frame.writeText(
                    hint,
                    x: hintX,
                    y: rowIdx,
                    fg: style.fg,
                    bg: style.bg,
                    attributes: style.attributes
                )
            }

            // Fill gaps for selected/styled rows
            if isSelected || !item.enabled {
                let labelEnd = item.label.count
                let hintStart = item.keyHint.map { frame.rect.width - $0.count } ?? frame.rect.width
                for fillX in labelEnd..<hintStart {
                    frame.setCell(x: fillX, y: rowIdx, cell: Cell(
                        character: " ", fg: style.fg, bg: style.bg, attributes: style.attributes
                    ))
                }
            }
        }
    }
}

// MARK: - AccessibleWidget

extension Menu: AccessibleWidget {
    /// An accessibility label describing the menu, including item count and currently selected item.
    public var accessibilityLabel: AccessibilityLabel {
        let count = items.count
        let selected = selectedIndex < count ? items[selectedIndex].label : ""
        return AccessibilityLabel(
            role: .menu,
            label: "Menu with \(count) items, selected: \(selected)",
            hint: "Enter to activate, arrow keys to navigate",
            childCount: count
        )
    }
}
