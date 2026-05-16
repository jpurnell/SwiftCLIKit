// SSHBackend.swift
// SwiftCLIKitSSH
// Created by Justin Purnell on 2026-04-10.

import Foundation
import SwiftCLIKit
import NIOCore
import NIOSSH

/// A `TerminalBackend` that operates over an SSH channel.
///
/// Reads input bytes fed by the NIO channel handler and writes output
/// through a provided closure. The SSH channel is inherently in raw mode,
/// so ``enableRawMode()`` and ``disableRawMode()`` are no-ops.
///
/// ```swift
/// let backend = SSHBackend(
///     initialSize: TerminalSize(columns: 120, rows: 40),
///     outputHandler: { text in channel.write(text) }
/// )
/// backend.feedInput([0x41])  // inject 'A'
/// ```
///
/// - Note: The ``readKey()`` method currently returns `nil` as a placeholder.
///   Full integration requires an async key reader, planned for a future release.
// Justification: NSLock protects mutable size; NIO channel access serialized through event loop
public final class SSHBackend: TerminalBackend, @unchecked Sendable {
    private let inputBuffer: AsyncStream<UInt8>
    private let inputContinuation: AsyncStream<UInt8>.Continuation
    private let outputHandler: @Sendable (String) -> Void
    private let lock = NSLock()
    private var size: TerminalSize

    /// Errors that can occur during SSH backend initialization.
    public enum Error: Swift.Error {
        /// The async stream continuation was unexpectedly unavailable.
        case continuationUnavailable
    }

    /// Creates an SSH backend with the given initial terminal size and output handler.
    /// - Parameters:
    ///   - initialSize: The client's reported terminal dimensions.
    ///   - outputHandler: A closure called with strings to send to the SSH client.
    /// - Throws: ``Error/continuationUnavailable`` if the async stream continuation
    ///   cannot be obtained.
    public init(
        initialSize: TerminalSize = TerminalSize(columns: 80, rows: 24),
        outputHandler: @escaping @Sendable (String) -> Void
    ) throws {
        self.size = initialSize
        self.outputHandler = outputHandler
        var cont: AsyncStream<UInt8>.Continuation?
        self.inputBuffer = AsyncStream { cont = $0 }
        guard let continuation = cont else {
            throw Error.continuationUnavailable
        }
        self.inputContinuation = continuation
    }

    /// Feeds raw bytes from the SSH channel into the input buffer.
    ///
    /// Called by the SSH channel handler when data arrives from the client.
    /// - Parameter bytes: The raw bytes received from the SSH channel.
    public func feedInput(_ bytes: [UInt8]) {
        for byte in bytes {
            inputContinuation.yield(byte)
        }
    }

    /// Updates the terminal size, typically in response to a window-change request.
    /// - Parameter newSize: The new terminal dimensions.
    public func updateSize(_ newSize: TerminalSize) {
        lock.lock()
        defer { lock.unlock() }
        size = newSize
    }

    // MARK: - TerminalBackend Conformance

    /// No-op: SSH channels are already in raw mode.
    public func enableRawMode() throws { }

    /// No-op: SSH channels do not have a "cooked" mode to restore.
    public func disableRawMode() { }

    /// Reads the next key from the SSH input stream.
    ///
    /// - Note: Currently returns `nil` as a placeholder. Full async key reading
    ///   integration is planned for a future release.
    /// - Returns: The next `Key`, or `nil`.
    public func readKey() -> Key? {
        // Placeholder: full implementation needs async byte reading
        // to bridge NIO's event-driven delivery with the synchronous readKey() API.
        nil
    }

    /// Returns the current terminal dimensions as reported by the SSH client.
    public func terminalSize() -> TerminalSize {
        lock.lock()
        defer { lock.unlock() }
        return size
    }

    /// Writes a string to the SSH channel via the output handler.
    /// - Parameter string: The text to send to the client.
    public func write(_ string: String) {
        outputHandler(string)
    }

    /// Sends the alternate screen enter sequence to the SSH client.
    public func enterAlternateScreen() {
        write("\u{1B}[?1049h")
    }

    /// Sends the alternate screen leave sequence to the SSH client.
    public func leaveAlternateScreen() {
        write("\u{1B}[?1049l")
    }

    /// Sends the mouse tracking enable sequence to the SSH client.
    public func enableMouse() {
        write(MouseMode.enable)
    }

    /// Sends the mouse tracking disable sequence to the SSH client.
    public func disableMouse() {
        write(MouseMode.disable)
    }

    /// Sends the cursor hide sequence to the SSH client.
    public func hideCursor() {
        write(CursorControl.hide)
    }

    /// Sends the cursor show sequence to the SSH client.
    public func showCursor() {
        write(CursorControl.show)
    }
}
