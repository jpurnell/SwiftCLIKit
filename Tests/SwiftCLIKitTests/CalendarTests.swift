// CalendarTests.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Testing
import Foundation
@testable import SwiftCLIKit

@Suite("CalendarView")
struct CalendarTests {

    private func makeFrame(width: Int, height: Int) -> Frame {
        let buf = CellBuffer(width: width, height: height)
        return Frame(buffer: buf, rect: Rect(x: 0, y: 0, width: width, height: height))
    }

    private func allText(from buf: CellBuffer) -> String {
        var result = ""
        for y in 0..<buf.height {
            for x in 0..<buf.width {
                result.append(buf[x, y].character)
            }
        }
        return result
    }

    @Test("April 2026 has 30 days and day names visible")
    func aprilTwentySix() {
        var frame = makeFrame(width: 28, height: 8)
        let cal = CalendarView(year: 2026, month: 4)
        cal.render(into: &frame)
        let buf = frame.cellBuffer
        let text = allText(from: buf)
        // "30" should be present (April has 30 days)
        #expect(text.contains("30"))
        // Day name abbreviations should be present (e.g., "Mo" or "Tu")
        #expect(text.contains("Mo") || text.contains("Tu") || text.contains("Su"))
    }

    @Test("Selected day has highlight style applied")
    func selectedDay() {
        var frame = makeFrame(width: 28, height: 8)
        let selectedStyle = CellStyle(fg: .ansi8(.red), attributes: [.reverse])
        let cal = CalendarView(year: 2026, month: 4, selectedDay: 15, selectedStyle: selectedStyle)
        cal.render(into: &frame)
        let buf = frame.cellBuffer
        // Find the "1" and "5" of "15" and check if the cell has the selected style
        var found = false
        for y in 0..<buf.height {
            for x in 0..<(buf.width - 1) {
                if buf[x, y].character == "1" && buf[x + 1, y].character == "5" {
                    let cell = buf[x, y]
                    if cell.fg == .ansi8(.red) || cell.attributes.contains(.reverse) {
                        found = true
                    }
                }
            }
        }
        #expect(found)
    }

    @Test("Leap year February 2028 has 29 days")
    func leapYear() {
        var frame = makeFrame(width: 28, height: 8)
        let cal = CalendarView(year: 2028, month: 2)
        cal.render(into: &frame)
        let buf = frame.cellBuffer
        let text = allText(from: buf)
        #expect(text.contains("29"))
    }

    @Test("Highlighted days have highlight style")
    func highlightedDays() {
        var frame = makeFrame(width: 28, height: 8)
        let hlStyle = CellStyle(fg: .ansi8(.yellow), attributes: [.bold])
        let cal = CalendarView(
            year: 2026, month: 4,
            highlightedDays: [1, 10],
            highlightStyle: hlStyle
        )
        cal.render(into: &frame)
        let buf = frame.cellBuffer
        // Find a cell with "1" and "0" adjacent for day 10
        var foundHighlight = false
        for y in 0..<buf.height {
            for x in 0..<(buf.width - 1) {
                if buf[x, y].character == "1" && buf[x + 1, y].character == "0" {
                    let cell = buf[x, y]
                    if cell.fg == .ansi8(.yellow) || cell.attributes.contains(.bold) {
                        foundHighlight = true
                    }
                }
            }
        }
        #expect(foundHighlight)
    }
}
