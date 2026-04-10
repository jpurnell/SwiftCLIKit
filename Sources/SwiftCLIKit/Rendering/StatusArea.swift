// StatusArea.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Foundation

/// A thread-safe rolling message area for displaying status lines in a terminal UI.
///
/// `StatusArea` keeps a bounded list of the most recent messages and can render
/// them as truncated, optionally dimmed lines.
public final class StatusArea: @unchecked Sendable {
    // Justification: NSLock-protected mutations only

    private let maxMessages: Int
    private var messages: [String] = []
    private let lock = NSLock()

    /// Creates a status area that retains up to `maxMessages` lines.
    /// - Parameter maxMessages: Maximum number of messages to keep. Defaults to 5.
    public init(maxMessages: Int = 5) { self.maxMessages = maxMessages }

    /// Appends a message, evicting the oldest if at capacity.
    /// - Parameter message: The status message to display.
    public func push(_ message: String) {
        lock.lock()
        defer { lock.unlock() }
        messages.append(message)
        if messages.count > maxMessages {
            messages.removeFirst()
        }
    }

    /// Removes all messages.
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        messages.removeAll()
    }

    /// Renders the current messages as an array of display-ready strings.
    /// - Parameter width: Maximum visible width for each line.
    /// - Parameter colorize: When `true`, wraps each line in dim ANSI styling.
    /// - Returns: An array of formatted, truncated message strings.
    public func render(width: Int, colorize: Bool) -> [String] {
        lock.lock()
        let snapshot = messages
        lock.unlock()
        return snapshot.map { message in
            var line = ANSIStringMetrics.truncateVisible(message, to: width)
            if colorize {
                line = ANSICodes.dim + line + ANSICodes.reset
            }
            return line
        }
    }

    /// The number of messages currently stored.
    public var lineCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return messages.count
    }
}
