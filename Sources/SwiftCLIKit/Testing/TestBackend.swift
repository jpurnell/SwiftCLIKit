// TestBackend.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Foundation

/// An in-memory terminal backend for headless testing.
///
/// `TestBackend` captures rendered buffers and allows injecting events
/// into the event stream without a real terminal.
///
/// ```swift
/// let backend = TestBackend(width: 80, height: 24)
/// await backend.inject(.key(.character("a")))
/// ```
public final class TestBackend: TerminalBackend, @unchecked Sendable {
    // Justification: internal lock protects buffer and event queue mutations
    private let lock = NSLock()
    private var buffer: CellBuffer
    private var history: [CellBuffer] = []
    private var eventContinuation: AsyncStream<Event>.Continuation?
    private var _eventStream: AsyncStream<Event>
    private var writtenOutput: [String] = []
    private var _isRawMode: Bool = false
    private var _isAlternateScreen: Bool = false
    private var _isMouseEnabled: Bool = false
    private var _isCursorHidden: Bool = false

    /// The width of the virtual terminal in columns.
    public let width: Int
    /// The height of the virtual terminal in rows.
    public let height: Int

    /// Creates a test backend with the given dimensions.
    /// - Parameters:
    ///   - width: Number of columns.
    ///   - height: Number of rows.
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.buffer = CellBuffer(width: width, height: height)
        var cont: AsyncStream<Event>.Continuation?
        self._eventStream = AsyncStream { cont = $0 }
        self.eventContinuation = cont
    }

    /// The current rendered buffer.
    public var currentBuffer: CellBuffer {
        lock.lock()
        defer { lock.unlock() }
        return buffer
    }

    /// Injects a single event into the event stream.
    /// - Parameter event: The event to inject.
    public func inject(_ event: Event) async {
        let cont = getContinuation()
        cont?.yield(event)
    }

    /// Injects a sequence of events with an optional delay between each.
    /// - Parameters:
    ///   - events: The events to inject in order.
    ///   - delay: The delay between each event (default: zero).
    public func injectSequence(_ events: [Event], delay: Duration = .zero) async {
        for event in events {
            let cont = getContinuation()
            cont?.yield(event)
            if delay > .zero {
                try? await Task.sleep(for: delay)
            }
        }
    }

    /// Thread-safe access to the event continuation, callable from async contexts.
    private nonisolated func getContinuation() -> AsyncStream<Event>.Continuation? {
        lock.lock()
        defer { lock.unlock() }
        return eventContinuation
    }

    /// Waits for the next render cycle to complete.
    public func waitForRender() async {
        await Task.yield()
    }

    /// The async stream of events for consumption by the app runtime.
    public var eventStream: AsyncStream<Event> { _eventStream }

    /// All buffers that have been submitted via ``submitRender(_:)``.
    public var renderHistory: [CellBuffer] {
        lock.lock()
        defer { lock.unlock() }
        return history
    }

    /// Clears the render history.
    public func clearHistory() {
        lock.lock()
        defer { lock.unlock() }
        history.removeAll()
    }

    /// Called by the App runtime to submit a rendered buffer.
    /// - Parameter buf: The buffer to record.
    internal func submitRender(_ buf: CellBuffer) {
        lock.lock()
        buffer = buf
        history.append(buf)
        lock.unlock()
    }

    // MARK: - TerminalBackend Conformance

    /// Enters raw mode (no-op for test backend).
    public func enableRawMode() throws {
        lock.lock()
        defer { lock.unlock() }
        _isRawMode = true
    }

    /// Restores original terminal mode (no-op for test backend).
    public func disableRawMode() {
        lock.lock()
        defer { lock.unlock() }
        _isRawMode = false
    }

    /// Returns `nil` immediately (use ``inject(_:)`` for event-driven testing).
    public func readKey() -> Key? { nil }

    /// Returns the configured test terminal dimensions.
    public func terminalSize() -> TerminalSize {
        TerminalSize(columns: width, rows: height)
    }

    /// Records the string for later assertion via ``allWrittenOutput``.
    /// - Parameter string: The text that would be written to a real terminal.
    public func write(_ string: String) {
        lock.lock()
        defer { lock.unlock() }
        writtenOutput.append(string)
    }

    /// Marks the alternate screen as active (no-op for test backend).
    public func enterAlternateScreen() {
        lock.lock()
        defer { lock.unlock() }
        _isAlternateScreen = true
    }

    /// Marks the alternate screen as inactive (no-op for test backend).
    public func leaveAlternateScreen() {
        lock.lock()
        defer { lock.unlock() }
        _isAlternateScreen = false
    }

    /// Marks mouse tracking as enabled (no-op for test backend).
    public func enableMouse() {
        lock.lock()
        defer { lock.unlock() }
        _isMouseEnabled = true
    }

    /// Marks mouse tracking as disabled (no-op for test backend).
    public func disableMouse() {
        lock.lock()
        defer { lock.unlock() }
        _isMouseEnabled = false
    }

    /// Marks the cursor as hidden (no-op for test backend).
    public func hideCursor() {
        lock.lock()
        defer { lock.unlock() }
        _isCursorHidden = true
    }

    /// Marks the cursor as visible (no-op for test backend).
    public func showCursor() {
        lock.lock()
        defer { lock.unlock() }
        _isCursorHidden = false
    }

    // MARK: - Test Inspection

    /// All strings that have been written through the ``write(_:)`` method.
    public var allWrittenOutput: [String] {
        lock.lock()
        defer { lock.unlock() }
        return writtenOutput
    }

    /// Whether raw mode is currently active.
    public var isRawMode: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isRawMode
    }

    /// Whether the alternate screen buffer is active.
    public var isAlternateScreen: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isAlternateScreen
    }

    /// Whether mouse tracking is enabled.
    public var isMouseEnabled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isMouseEnabled
    }

    /// Whether the cursor is hidden.
    public var isCursorHidden: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isCursorHidden
    }
}
