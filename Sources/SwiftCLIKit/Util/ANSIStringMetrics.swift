// ANSIStringMetrics.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Foundation

/// Utilities for measuring and manipulating strings that contain ANSI escape sequences.
public enum ANSIStringMetrics: Sendable {

    // MARK: - ANSI escape stripping

    /// Strips ANSI escape sequences from a string.
    private static func stripANSI(_ s: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "\u{001B}\\[[0-9;]*[A-Za-z]") else {
            return s
        }
        let range = NSRange(s.startIndex..., in: s)
        return regex.stringByReplacingMatches(in: s, range: range, withTemplate: "")
    }

    // MARK: - Visible length

    /// Returns the visible (non-escape) display width of a string, using ``UnicodeWidth``.
    /// - Parameter s: A string possibly containing ANSI escape sequences.
    /// - Returns: The column width after stripping escapes.
    public static func visibleLength(_ s: String) -> Int {
        let stripped = stripANSI(s)
        return UnicodeWidth.displayWidth(stripped)
    }

    // MARK: - Pad to visible width

    /// Right-pads a string with spaces so its visible width reaches the target.
    /// - Parameter s: The input string (may contain ANSI escapes).
    /// - Parameter width: The desired visible width.
    /// - Returns: The padded string, unchanged if already at or beyond the target width.
    public static func padVisible(_ s: String, to width: Int) -> String {
        let visible = visibleLength(s)
        guard visible < width else { return s }
        return s + String(repeating: " ", count: width - visible)
    }

    // MARK: - Truncate to visible width

    /// Truncates a string to fit within a visible column budget, preserving ANSI escapes
    /// and appending a reset sequence if any escape was left open.
    /// - Parameter s: The input string (may contain ANSI escapes).
    /// - Parameter maxWidth: The maximum visible column width.
    /// - Returns: The truncated string with ANSI state properly closed.
    public static func truncateVisible(_ s: String, to maxWidth: Int) -> String {
        guard maxWidth >= 0 else { return "" }

        var result = ""
        var currentWidth = 0
        var inEscape = false
        var hadANSI = false
        var hasOpenANSI = false

        let characters = Array(s)
        var i = 0

        while i < characters.count {
            let ch = characters[i]

            // Check for ESC starting an ANSI sequence
            if ch == "\u{001B}" {
                // Look ahead for '['
                if i + 1 < characters.count, characters[i + 1] == "[" {
                    inEscape = true
                    hadANSI = true
                    hasOpenANSI = true
                    result.append(ch)
                    i += 1
                    continue
                }
            }

            if inEscape {
                result.append(ch)
                // ANSI escape ends at a letter A-Z or a-z
                let scalar = ch.unicodeScalars.first
                if let s = scalar {
                    let v = s.value
                    if (v >= 0x41 && v <= 0x5A) || (v >= 0x61 && v <= 0x7A) {
                        inEscape = false
                        // Check if this was a reset sequence
                        if result.hasSuffix("\u{001B}[0m") {
                            hasOpenANSI = false
                        }
                    }
                }
                i += 1
                continue
            }

            let charWidth = UnicodeWidth.width(of: ch)

            // Would this character exceed the budget?
            if currentWidth + charWidth > maxWidth {
                // Wide char doesn't fit — pad with spaces for remaining columns
                let remaining = maxWidth - currentWidth
                if remaining > 0 {
                    result += String(repeating: " ", count: remaining)
                }
                break
            }

            result.append(ch)
            currentWidth += charWidth
            i += 1
        }

        // If we opened ANSI escapes and haven't reset, append reset
        if hasOpenANSI {
            result += ANSICodes.reset
        }

        return result
    }
}
