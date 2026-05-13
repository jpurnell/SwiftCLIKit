// TerminalSize.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

#if canImport(Darwin) || canImport(Glibc)
private let resizeLock = NSLock()
// Justification: access is serialized through resizeLock (NSLock)
nonisolated(unsafe) private var resizeCallbacks: [ObjectIdentifier: @Sendable (TerminalSize) -> Void] = [:]
// Justification: access is serialized through resizeLock (NSLock)
nonisolated(unsafe) private var signalHandlerInstalled = false

private func installSignalHandler() {
    guard !signalHandlerInstalled else { return }
    signalHandlerInstalled = true
    signal(SIGWINCH) { _ in
        let size = TerminalSize.current()
        resizeLock.lock()
        let callbacks = resizeCallbacks
        resizeLock.unlock()
        for (_, callback) in callbacks {
            callback(size)
        }
    }
}
#endif

/// The dimensions of the terminal window in columns and rows.
public struct TerminalSize: Sendable, Equatable {
    /// Number of character columns.
    public var columns: Int
    /// Number of character rows.
    public var rows: Int

    /// Creates a terminal size with the given dimensions.
    /// - Parameter columns: Column count. Defaults to 80.
    /// - Parameter rows: Row count. Defaults to 24.
    public init(columns: Int = 80, rows: Int = 24) {
        self.columns = columns
        self.rows = rows
    }

    /// Queries the OS for the current terminal size via `ioctl(TIOCGWINSZ)`.
    /// - Parameter fileDescriptor: The descriptor to query. Defaults to STDOUT.
    /// - Parameter fallback: Returned when the query fails (e.g. not a TTY).
    /// - Returns: The detected terminal size, or `fallback`.
    public static func current(
        fileDescriptor: Int32 = 1,  // STDOUT_FILENO
        fallback: TerminalSize = TerminalSize(columns: 80, rows: 24)
    ) -> TerminalSize {
        #if canImport(Darwin) || canImport(Glibc)
        var ws = winsize()
        guard ioctl(fileDescriptor, UInt(TIOCGWINSZ), &ws) == 0 else {
            return fallback
        }
        let cols = Int(ws.ws_col)
        let rows = Int(ws.ws_row)
        guard cols > 0, rows > 0 else { return fallback }
        return TerminalSize(columns: cols, rows: rows)
        #else
        return fallback
        #endif
    }

    /// Registers a callback to be invoked when the terminal window is resized (SIGWINCH).
    ///
    /// Hold the returned token for the lifetime of the subscription; the callback
    /// is automatically deregistered when the token is deallocated.
    /// - Parameter onChange: Called with the new size on each resize event.
    /// - Returns: A ``ResizeToken`` whose lifetime controls the subscription.
    public static func onResize(_ onChange: @escaping @Sendable (TerminalSize) -> Void) -> ResizeToken {
        let token = ResizeToken()
        let identifier = ObjectIdentifier(token)
        #if canImport(Darwin) || canImport(Glibc)
        resizeLock.lock()
        resizeCallbacks[identifier] = onChange
        installSignalHandler()
        resizeLock.unlock()
        #endif
        token.identifier = identifier
        return token
    }
}

/// An opaque token whose lifetime controls a SIGWINCH resize subscription.
/// Deallocation automatically deregisters the callback.
// Justification: identifier only written once during registration; dealloc removal is lock-protected
public final class ResizeToken: @unchecked Sendable {
    fileprivate var identifier: ObjectIdentifier?

    deinit {
        #if canImport(Darwin) || canImport(Glibc)
        guard let identifier = identifier else { return }
        resizeLock.lock()
        resizeCallbacks.removeValue(forKey: identifier)
        resizeLock.unlock()
        #endif
    }
}
