// ANSIStringMetricsTests.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Testing
import Foundation
@testable import SwiftCLIKit

@Suite("ANSIStringMetrics")
struct ANSIStringMetricsTests {

    @Test("Plain text visible length equals character count")
    func plainText() {
        #expect(ANSIStringMetrics.visibleLength("hello") == 5)
    }

    @Test("ANSI colored text visible length excludes escape sequences")
    func ansiColored() {
        #expect(ANSIStringMetrics.visibleLength("\u{001B}[31mred\u{001B}[0m") == 3)
    }

    @Test("Multiple ANSI escapes are stripped from visible length")
    func multipleEscapes() {
        #expect(ANSIStringMetrics.visibleLength("\u{001B}[1m\u{001B}[31mbold red\u{001B}[0m") == 8)
    }

    @Test("CJK characters with ANSI have correct visible width")
    func cjkWithANSI() {
        #expect(ANSIStringMetrics.visibleLength("\u{001B}[31m\u{4E2D}\u{6587}\u{001B}[0m") == 4)
    }

    @Test("Emoji with ANSI has correct visible width")
    func emojiWithANSI() {
        #expect(ANSIStringMetrics.visibleLength("\u{001B}[32m\u{1F600}\u{001B}[0m") == 2)
    }

    @Test("padVisible pads string to target visible width")
    func padVisible() {
        let padded = ANSIStringMetrics.padVisible("hi", to: 10)
        #expect(ANSIStringMetrics.visibleLength(padded) == 10)
    }

    @Test("padVisible on already-wide string is unchanged")
    func padAlreadyWide() {
        let result = ANSIStringMetrics.padVisible("hello world", to: 5)
        #expect(result == "hello world")
    }

    @Test("padVisible on CJK character pads correctly")
    func padCJK() {
        let padded = ANSIStringMetrics.padVisible("\u{4E2D}", to: 4)
        #expect(ANSIStringMetrics.visibleLength(padded) == 4)
    }

    @Test("truncateVisible truncates plain text to target width")
    func truncateBasic() {
        let truncated = ANSIStringMetrics.truncateVisible("hello world", to: 5)
        #expect(ANSIStringMetrics.visibleLength(truncated) == 5)
        #expect(truncated.hasPrefix("hello"))
    }

    @Test("truncateVisible on colored text includes reset at end")
    func truncateWithANSI() {
        let colored = "\u{001B}[31mhello world\u{001B}[0m"
        let truncated = ANSIStringMetrics.truncateVisible(colored, to: 5)
        #expect(truncated.contains("\u{001B}[0m"))
    }

    @Test("truncateVisible on wide boundary pads instead of splitting a wide character")
    func truncateWideBoundary() {
        // "A" = width 1, "中" = width 2, "B" = width 1 → total 4
        let truncated = ANSIStringMetrics.truncateVisible("A\u{4E2D}B", to: 2)
        #expect(ANSIStringMetrics.visibleLength(truncated) == 2)
    }

    @Test("Empty string has visible length 0")
    func emptyString() {
        #expect(ANSIStringMetrics.visibleLength("") == 0)
    }
}
