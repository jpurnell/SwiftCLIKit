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
public final class TestBackend: @unchecked Sendable {
    // Justification: internal lock protects buffer and event queue mutations
    private let lock = NSLock()
    private var buffer: CellBuffer
    private var history: [CellBuffer] = []
    private var eventContinuation: AsyncStream<Event>.Continuation?
    private var _eventStream: AsyncStream<Event>

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
}
