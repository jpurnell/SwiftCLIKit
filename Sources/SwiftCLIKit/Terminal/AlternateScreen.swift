// AlternateScreen.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// Manages the terminal alternate screen buffer.
///
/// On creation, switches the terminal to the alternate screen.
/// On deallocation, restores the original screen content.
/// The original screen is automatically restored when the instance is deallocated (RAII pattern).
///
/// ```swift
/// func runFullscreenUI() {
///     let screen = AlternateScreen()
///     // Terminal is now on the alternate buffer.
///     print(CursorControl.hide)
///     drawUI()
///     // When `screen` goes out of scope, the original content reappears.
/// }
/// ```
public final class AlternateScreen: @unchecked Sendable {
    // Justification: enter/leave only called from main thread at app lifecycle boundaries

    private let fd: Int32

    /// Whether the alternate screen is currently active.
    public private(set) var isActive: Bool = false

    /// Creates an alternate screen on the given file descriptor.
    /// - Parameter fileDescriptor: The POSIX file descriptor to write to (default: STDOUT).
    public init(fileDescriptor: Int32 = 1) {
        self.fd = fileDescriptor
        writeEscape("\u{001B}[?1049h")
        isActive = true
    }

    deinit {
        writeEscape("\u{001B}[?1049l")
    }

    private func writeEscape(_ seq: String) {
        let bytes = Array(seq.utf8)
        _ = bytes.withUnsafeBufferPointer { ptr in
            write(fd, ptr.baseAddress, ptr.count)
        }
    }
}
