// AccessibilityAnnouncerTests.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Testing
import Foundation
@testable import SwiftCLIKit

// Justification: Test-only capture buffer used synchronously within each test; no concurrent mutation.
private final class CaptureBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []

    func append(_ value: String) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(value)
    }

    var values: [String] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}

@Suite("AccessibilityAnnouncer")
struct AccessibilityAnnouncerTests {

    @Test("Announce emits message when enabled")
    func announceWhenEnabled() {
        let captured = CaptureBuffer()
        let announcer = AccessibilityAnnouncer(
            channel: .custom { captured.append($0) },
            settings: AccessibilitySettings(isEnabled: true)
        )
        announcer.announce("Hello")
        #expect(captured.values == ["Hello"])
    }

    @Test("Announce is silent when disabled")
    func announceWhenDisabled() {
        let captured = CaptureBuffer()
        let announcer = AccessibilityAnnouncer(
            channel: .custom { captured.append($0) },
            settings: AccessibilitySettings(isEnabled: false)
        )
        announcer.announce("Hello")
        #expect(captured.values.isEmpty)
    }

    @Test("Focus changed emits focus ID and label")
    func focusChanged() {
        let captured = CaptureBuffer()
        let announcer = AccessibilityAnnouncer(
            channel: .custom { captured.append($0) },
            settings: AccessibilitySettings(isEnabled: true, verbosity: .standard)
        )
        let label = AccessibilityLabel(role: .button, label: "Save", value: "Ready")
        announcer.focusChanged(from: "a", to: "b", label: label)
        #expect(captured.values.count == 1)
        let output = captured.values[0]
        #expect(output.contains("Focus: b"))
        #expect(output.contains("button: Save"))
    }

    @Test("Value changed emits update with widget ID")
    func valueChanged() {
        let captured = CaptureBuffer()
        let announcer = AccessibilityAnnouncer(
            channel: .custom { captured.append($0) },
            settings: AccessibilitySettings(isEnabled: true)
        )
        let label = AccessibilityLabel(role: .gauge, label: "CPU", value: "80%")
        announcer.valueChanged(widgetID: "cpu-gauge", label: label)
        #expect(captured.values.count == 1)
        #expect(captured.values[0].contains("Updated cpu-gauge"))
        #expect(captured.values[0].contains("gauge: CPU"))
    }

    @Test("Stderr channel does not crash")
    func stderrChannel() {
        let announcer = AccessibilityAnnouncer(
            channel: .stderr,
            settings: AccessibilitySettings(isEnabled: true)
        )
        // Just verify no crash; stderr output can't be captured easily
        announcer.announce("stderr test")
    }
}
