// Table.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Foundation

/// A tabular data widget that renders rows and columns with optional headers and selection.
///
/// `Table` is generic over its row type, allowing any `Sendable` model to be displayed.
/// Each ``Column`` defines a header, width constraint, and rendering closure.
///
/// ```swift
/// let table = Table(
///     columns: [
///         Table.Column(header: "Name", width: .fixed(10)) { row in row.name },
///         Table.Column(header: "Age", width: .fixed(5)) { row in "\(row.age)" },
///     ],
///     rows: people,
///     state: TableState()
/// )
/// table.render(into: &frame)
/// ```
public struct Table<Row: Sendable>: Sendable {
    /// A column definition for a ``Table``.
    public struct Column: Sendable {
        /// The header text displayed at the top of this column.
        public var header: String
        /// The width constraint for this column.
        public var width: Layout.Constraint
        /// A closure that extracts display text from a row.
        public var render: @Sendable (Row) -> String

        /// Creates a column definition.
        /// - Parameters:
        ///   - header: The header text.
        ///   - width: The width constraint for this column.
        ///   - render: A closure that produces the display text for a given row.
        public init(
            header: String,
            width: Layout.Constraint,
            render: @escaping @Sendable (Row) -> String
        ) {
            self.header = header
            self.width = width
            self.render = render
        }
    }

    /// The columns to display.
    public var columns: [Column]
    /// The row data to render.
    public var rows: [Row]
    /// The current selection and scroll state.
    public var state: TableState
    /// The style applied to the selected row.
    public var highlightStyle: CellStyle
    /// The style applied to the header row.
    public var headerStyle: CellStyle
    /// Whether to show a sort indicator character in the header.
    public var sortIndicator: (column: Int, ascending: Bool)?
    /// Whether to show a scrollbar when content overflows.
    public var showScrollbar: Bool

    /// Creates a table widget.
    /// - Parameters:
    ///   - columns: The column definitions.
    ///   - rows: The data rows.
    ///   - state: The table state (default: new state).
    ///   - highlightStyle: Style for the selected row (default: reverse video).
    ///   - headerStyle: Style for the header row (default: bold).
    ///   - sortIndicator: Optional sort indicator as (column index, ascending).
    ///   - showScrollbar: Whether to show a scrollbar (default: false).
    public init(
        columns: [Column],
        rows: [Row],
        state: TableState = TableState(),
        highlightStyle: CellStyle = CellStyle(attributes: [.reverse]),
        headerStyle: CellStyle = CellStyle(attributes: [.bold]),
        sortIndicator: (column: Int, ascending: Bool)? = nil,
        showScrollbar: Bool = false
    ) {
        self.columns = columns
        self.rows = rows
        self.state = state
        self.highlightStyle = highlightStyle
        self.headerStyle = headerStyle
        self.sortIndicator = sortIndicator
        self.showScrollbar = showScrollbar
    }

    /// Renders this table into the given frame.
    /// - Parameter frame: The frame to render into.
    public func render(into frame: inout Frame) {
        guard frame.rect.width > 0, frame.rect.height > 0 else { return }

        // Resolve column widths (use fixed values directly)
        let columnWidths: [Int] = columns.map { col in
            switch col.width {
            case .fixed(let w): return w
            case .min(let w): return w
            case .max(let w): return w
            case .ratio(let num, let den):
                guard den > 0 else { return 0 }
                return (num * frame.rect.width) / den
            case .percentage(let pct):
                return (Int(pct) * frame.rect.width) / 100
            }
        }

        // Row 0: render header
        var colX = 0
        for (i, col) in columns.enumerated() {
            guard i < columnWidths.count else { break }
            var headerText = col.header
            if let sort = sortIndicator, sort.column == i {
                headerText += sort.ascending ? "▲" : "▼"
            }
            frame.writeText(
                headerText,
                x: colX,
                y: 0,
                fg: headerStyle.fg,
                bg: headerStyle.bg,
                attributes: headerStyle.attributes
            )
            colX += columnWidths[i]
        }

        // Data rows: start at y=1, respecting scrollOffset
        let visibleRowCount = frame.rect.height - 1
        guard visibleRowCount > 0 else { return }

        for rowIdx in 0..<visibleRowCount {
            let dataIdx = state.scrollOffset + rowIdx
            guard dataIdx < rows.count else { break }
            let row = rows[dataIdx]
            let isSelected = (state.selectedRow == dataIdx)
            let style = isSelected ? highlightStyle : CellStyle()

            var cx = 0
            for (i, col) in columns.enumerated() {
                guard i < columnWidths.count else { break }
                let text = col.render(row)
                frame.writeText(
                    text,
                    x: cx,
                    y: rowIdx + 1,
                    fg: style.fg,
                    bg: style.bg,
                    attributes: style.attributes
                )
                cx += columnWidths[i]
            }

            // If selected, fill remaining cells in the row with highlight style
            if isSelected {
                for fillX in cx..<frame.rect.width {
                    frame.setCell(x: fillX, y: rowIdx + 1, cell: Cell(
                        character: " ", fg: style.fg, bg: style.bg, attributes: style.attributes
                    ))
                }
            }
        }
    }
}

/// Selection and scroll state for a ``Table`` widget.
public struct TableState: Sendable, Equatable {
    /// The currently selected row index, or `nil` for no selection.
    public var selectedRow: Int?
    /// The scroll offset (first visible row index).
    public var scrollOffset: Int

    /// Creates a table state.
    /// - Parameters:
    ///   - selectedRow: The selected row index (default: nil).
    ///   - scrollOffset: The scroll offset (default: 0).
    public init(selectedRow: Int? = nil, scrollOffset: Int = 0) {
        self.selectedRow = selectedRow
        self.scrollOffset = scrollOffset
    }

    /// Moves the selection to the next row, scrolling if necessary.
    /// - Parameters:
    ///   - rowCount: The total number of rows.
    ///   - visibleRows: The number of rows visible in the viewport.
    public mutating func selectNext(rowCount: Int, visibleRows: Int) {
        guard rowCount > 0 else { return }
        let current = selectedRow ?? -1
        let next = min(current + 1, rowCount - 1)
        selectedRow = next
        if next >= scrollOffset + visibleRows {
            scrollOffset = next - visibleRows + 1
        }
    }

    /// Moves the selection to the previous row, scrolling if necessary.
    public mutating func selectPrevious() {
        guard let current = selectedRow else { return }
        let prev = max(current - 1, 0)
        selectedRow = prev
        if prev < scrollOffset {
            scrollOffset = prev
        }
    }
}

// MARK: - AccessibleWidget

extension Table: AccessibleWidget {
    /// An accessibility label describing the table, including row count and current selection.
    public var accessibilityLabel: AccessibilityLabel {
        let rowDesc = rows.count == 1 ? "1 row" : "\(rows.count) rows"
        var label = "Table with \(rowDesc)"
        if let sel = state.selectedRow {
            label += ", currently on row \(sel + 1)"
        }
        return AccessibilityLabel(
            role: .table,
            label: label,
            hint: "Use arrow keys to navigate rows",
            childCount: rows.count
        )
    }
}
