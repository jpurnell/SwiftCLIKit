// RealBackend.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// The default terminal backend using POSIX stdin/stdout.
///
/// Wraps ``RawTerminal``, ``KeyReader``, and ``AlternateScreen`` behind the
/// ``TerminalBackend`` protocol so the ``App`` runtime can drive a real terminal
/// session without knowing the concrete transport.
///
/// ```swift
/// let backend: any TerminalBackend = RealBackend()
/// try backend.enableRawMode()
/// backend.enterAlternateScreen()
/// // ... run event loop ...
/// backend.leaveAlternateScreen()
/// backend.disableRawMode()
/// ```
// Justification: terminal state managed in init/deinit lifecycle; file descriptors are OS-level thread-safe
public final class RealBackend: TerminalBackend, @unchecked Sendable {
    private let terminal: RawTerminal
    private let reader: KeyReader
    private var altScreen: AlternateScreen?

    /// Creates a real backend that reads from stdin and writes to stdout.
    public init() {
        self.terminal = RawTerminal()
        self.reader = KeyReader(terminal: terminal)
    }

    /// Enters raw mode.
    ///
    /// Raw mode is activated during ``RawTerminal`` initialization, so this
    /// method is provided for protocol conformance and is safe to call
    /// multiple times.
    public func enableRawMode() throws { /* already done in RawTerminal.init */ }

    /// Restores the original terminal mode.
    ///
    /// The terminal is restored during ``RawTerminal`` deinitialization.
    /// This method is provided for protocol conformance.
    public func disableRawMode() { /* done in RawTerminal.deinit */ }

    /// Reads and decodes the next key press, blocking until a byte is available.
    /// - Returns: The decoded ``Key``, or `nil` on EOF.
    public func readKey() -> Key? { reader.readKey() }

    /// Queries the OS for the current terminal dimensions.
    /// - Returns: The current ``TerminalSize``.
    public func terminalSize() -> TerminalSize { TerminalSize.current() }

    /// Writes a string to stdout.
    /// - Parameter string: The text to write.
    public func write(_ string: String) {
        let bytes = Array(string.utf8)
        bytes.withUnsafeBufferPointer { ptr in
            guard let base = ptr.baseAddress else { return }
            #if canImport(Darwin)
            _ = Darwin.write(1, base, ptr.count)
            #elseif canImport(Glibc)
            _ = Glibc.write(1, base, ptr.count)
            #endif
        }
        fflush(stdout)
    }

    /// Switches to the alternate screen buffer.
    public func enterAlternateScreen() {
        altScreen = AlternateScreen()
    }

    /// Restores the primary screen buffer.
    public func leaveAlternateScreen() {
        altScreen = nil  // deinit restores
    }

    /// Enables SGR extended mouse tracking.
    public func enableMouse() { write(MouseMode.enable) }

    /// Disables SGR extended mouse tracking.
    public func disableMouse() { write(MouseMode.disable) }

    /// Hides the cursor.
    public func hideCursor() { write(CursorControl.hide) }

    /// Shows the cursor.
    public func showCursor() { write(CursorControl.show) }
}
