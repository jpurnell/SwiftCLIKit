// SessionReplayTests.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import XCTest
@testable import SwiftCLIKit

// MARK: - Test Message Type

private enum TestMsg: Codable, Sendable, Equatable {
    case increment
    case decrement
    case set(Int)
}

private struct TestModel: Sendable, Equatable {
    var count: Int = 0
}

private func testUpdate(model: inout TestModel, message: TestMsg) -> [Cmd<TestMsg>] {
    switch message {
    case .increment:
        model.count += 1
    case .decrement:
        model.count -= 1
    case .set(let value):
        model.count = value
    }
    return [.none]
}

// MARK: - SessionRecorder Tests

final class SessionRecorderTests: XCTestCase {
    private var tempDir: String = ""

    override func setUp() {
        super.setUp()
        tempDir = NSTemporaryDirectory() + "SwiftCLIKitTests_\(UUID().uuidString)/"
        FileManager.default.createFile(atPath: tempDir, contents: nil)
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: tempDir)
        super.tearDown()
    }

    private func tempPath(_ name: String) -> String {
        tempDir + name
    }

    /// Record 3 entries and verify the file has 3 lines.
    func testRecordThreeEntriesProducesThreeLines() throws {
        let path = tempPath("three_entries.jsonl")
        let recorder = SessionRecorder<TestMsg>(outputPath: path)

        recorder.record(key: "a", timestamp: 0.0)
        recorder.record(key: "b", timestamp: 0.5)
        recorder.record(message: .increment, timestamp: 1.0)
        try recorder.close()

        let content = try String(contentsOfFile: path, encoding: .utf8)
        let lines = content.split(separator: "\n", omittingEmptySubsequences: true)
        XCTAssertEqual(lines.count, 3)
    }

    /// Record and close produces valid JSON-lines (each line is valid JSON).
    func testRecordAndCloseProducesValidJSONLines() throws {
        let path = tempPath("valid_json.jsonl")
        let recorder = SessionRecorder<TestMsg>(outputPath: path)

        recorder.record(key: "enter", timestamp: 0.0)
        recorder.record(message: .increment, timestamp: 0.5)
        recorder.record(message: .set(42), timestamp: 1.0)
        try recorder.close()

        let content = try String(contentsOfFile: path, encoding: .utf8)
        let lines = content.split(separator: "\n", omittingEmptySubsequences: true)
        let decoder = JSONDecoder()

        for line in lines {
            let data = Data(line.utf8)
            let entry = try decoder.decode(SessionEntry<TestMsg>.self, from: data)
            XCTAssertGreaterThanOrEqual(entry.timestamp, 0.0)
        }
    }

    /// Replay produces the correct number of model snapshots.
    func testReplayProducesCorrectModelCount() throws {
        let path = tempPath("replay_count.jsonl")
        let recorder = SessionRecorder<TestMsg>(outputPath: path)

        recorder.record(message: .increment, timestamp: 0.0)
        recorder.record(message: .increment, timestamp: 0.5)
        recorder.record(message: .decrement, timestamp: 1.0)
        recorder.record(key: "x", timestamp: 1.5) // key event, no snapshot
        try recorder.close()

        let player = SessionPlayer<TestModel, TestMsg>(
            inputPath: path,
            initialModel: TestModel(),
            update: testUpdate
        )
        let snapshots = try player.play()

        // 3 message entries produce 3 snapshots; key event is skipped
        XCTAssertEqual(snapshots.count, 3)
        XCTAssertEqual(snapshots[0].count, 1)
        XCTAssertEqual(snapshots[1].count, 2)
        XCTAssertEqual(snapshots[2].count, 1)
    }

    /// Empty file produces empty snapshots array.
    func testEmptyFileProducesEmptySnapshots() throws {
        let path = tempPath("empty.jsonl")
        FileManager.default.createFile(atPath: path, contents: Data())

        let player = SessionPlayer<TestModel, TestMsg>(
            inputPath: path,
            initialModel: TestModel(),
            update: testUpdate
        )
        let snapshots = try player.play()

        XCTAssertTrue(snapshots.isEmpty)
    }

    /// Corrupted line is skipped; valid lines still produce snapshots.
    func testCorruptedFileSkipsInvalidLines() throws {
        let path = tempPath("corrupted.jsonl")

        // Write a valid entry, then garbage, then another valid entry
        let recorder = SessionRecorder<TestMsg>(outputPath: path)
        recorder.record(message: .increment, timestamp: 0.0)
        try recorder.close()

        // Append corrupted line and another valid line
        let handle = FileHandle(forWritingAtPath: path)
        handle?.seekToEndOfFile()
        handle?.write(Data("NOT VALID JSON\n".utf8))

        // Write another valid entry manually
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let entry = SessionEntry<TestMsg>(timestamp: 1.0, kind: .message(.set(10)))
        if let data = try? encoder.encode(entry) {
            var line = data
            line.append(contentsOf: [UInt8(ascii: "\n")])
            handle?.write(line)
        }
        handle?.closeFile()

        let player = SessionPlayer<TestModel, TestMsg>(
            inputPath: path,
            initialModel: TestModel(),
            update: testUpdate
        )
        let snapshots = try player.play()

        // 2 valid message entries, corrupted line skipped
        XCTAssertEqual(snapshots.count, 2)
        XCTAssertEqual(snapshots[0].count, 1)  // increment
        XCTAssertEqual(snapshots[1].count, 10) // set(10)
    }
}
