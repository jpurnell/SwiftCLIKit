// ANSICodes.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Foundation

/// Standard and bright ANSI terminal colors (SGR 30-37 / 90-97).
public enum ANSIColor: UInt8, Sendable, CaseIterable {
    /// Standard colors (foreground codes 30-37).
    case black = 0, red, green, yellow, blue, magenta, cyan, white
    /// Bright/high-intensity colors (foreground codes 90-97).
    case brightBlack = 8, brightRed, brightGreen, brightYellow, brightBlue, brightMagenta, brightCyan, brightWhite
}

/// ANSI escape-sequence constants for screen control, text styling, and cursor manipulation.
public enum ANSICodes {
    /// Erase the entire screen (CSI 2J).
    public static let clearScreen = "\u{001B}[2J"
    /// Move cursor to row 1, column 1 (CSI H).
    public static let home = "\u{001B}[H"
    /// Reset all text attributes to default (SGR 0).
    public static let reset = "\u{001B}[0m"
    /// Enable bold/bright text (SGR 1).
    public static let bold = "\u{001B}[1m"
    /// Enable dim/faint text (SGR 2).
    public static let dim = "\u{001B}[2m"
    /// Enable italic text (SGR 3).
    public static let italic = "\u{001B}[3m"
    /// Enable underlined text (SGR 4).
    public static let underline = "\u{001B}[4m"
    /// Enable blinking text (SGR 5).
    public static let blink = "\u{001B}[5m"
    /// Swap foreground and background colors (SGR 7).
    public static let reverse = "\u{001B}[7m"
    /// Hide text (SGR 8).
    public static let hidden = "\u{001B}[8m"

    /// Returns the ANSI foreground color escape sequence for the given color.
    /// - Parameter color: The ANSI color to apply.
    /// - Returns: An escape string that sets the foreground color.
    public static func fg(_ color: ANSIColor) -> String {
        if color.rawValue < 8 {
            return "\u{001B}[\(30 + color.rawValue)m"
        }
        return "\u{001B}[\(90 + color.rawValue - 8)m"
    }

    /// Returns the ANSI background color escape sequence for the given color.
    /// - Parameter color: The ANSI color to apply.
    /// - Returns: An escape string that sets the background color.
    public static func bg(_ color: ANSIColor) -> String {
        if color.rawValue < 8 {
            return "\u{001B}[\(40 + color.rawValue)m"
        }
        return "\u{001B}[\(100 + color.rawValue - 8)m"
    }

    /// Returns an escape sequence that moves the cursor to a specific position.
    /// - Parameter row: The 1-based row number.
    /// - Parameter column: The 1-based column number.
    /// - Returns: A CSI cursor-position escape string.
    public static func cursorTo(row: Int, column: Int) -> String { "\u{001B}[\(row);\(column)H" }
    /// Make the cursor visible.
    public static let cursorShow = "\u{001B}[?25h"
    /// Hide the cursor.
    public static let cursorHide = "\u{001B}[?25l"
    /// Save the current cursor position (DECSC via CSI s).
    public static let saveCursor = "\u{001B}[s"
    /// Restore a previously saved cursor position (DECRC via CSI u).
    public static let restoreCursor = "\u{001B}[u"
}
