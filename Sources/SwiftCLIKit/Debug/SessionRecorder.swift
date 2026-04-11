// SessionRecorder.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Foundation

/// Records session entries to a file in JSON-lines format for later replay.
///
/// Each call to ``record(key:timestamp:)`` or ``record(message:timestamp:)``
/// appends one JSON line to the output file. Call ``close()`` when done to
/// flush and close the file handle.
///
/// ```swift
/// let recorder = SessionRecorder<MyMessage>(outputPath: "/tmp/session.jsonl")
/// recorder.record(key: "a", timestamp: 0.0)
/// recorder.record(message: .increment, timestamp: 0.5)
/// try recorder.close()
/// ```
// Justification: FileHandle is reference-type and thread-safe for sequential appends;
// the class is only used from a single recording context.
public final class SessionRecorder<Message: Codable & Sendable>: @unchecked Sendable {
    private let fileHandle: FileHandle
    private let encoder: JSONEncoder
    private let outputPath: String

    /// Creates a new session recorder that writes to the given file path.
    ///
    /// If the file does not exist, it is created. If it exists, it is truncated.
    /// - Parameter outputPath: The file system path for the recording output.
    public init(outputPath: String) {
        self.outputPath = outputPath
        let manager = FileManager.default
        if !manager.fileExists(atPath: outputPath) {
            manager.createFile(atPath: outputPath, contents: nil)
        } else {
            // Truncate existing file
            if let handle = FileHandle(forWritingAtPath: outputPath) {
                handle.truncateFile(atOffset: 0)
                handle.closeFile()
            }
        }
        self.fileHandle = FileHandle(forWritingAtPath: outputPath) ?? FileHandle.nullDevice
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.sortedKeys]
    }

    /// Records a key event at the given timestamp.
    /// - Parameters:
    ///   - description: Human-readable key description.
    ///   - timestamp: Seconds since session start.
    public func record(key description: String, timestamp: Double) {
        let entry = SessionEntry<Message>(
            timestamp: timestamp,
            kind: .keyEvent(KeyEventSnapshot(description: description))
        )
        writeLine(entry)
    }

    /// Records a resize event at the given timestamp.
    /// - Parameters:
    ///   - width: New terminal width in columns.
    ///   - height: New terminal height in rows.
    ///   - timestamp: Seconds since session start.
    public func record(resize width: Int, height: Int, timestamp: Double) {
        let entry = SessionEntry<Message>(
            timestamp: timestamp,
            kind: .resizeEvent(width: width, height: height)
        )
        writeLine(entry)
    }

    /// Records an application message at the given timestamp.
    /// - Parameters:
    ///   - message: The application message to record.
    ///   - timestamp: Seconds since session start.
    public func record(message: Message, timestamp: Double) {
        let entry = SessionEntry<Message>(
            timestamp: timestamp,
            kind: .message(message)
        )
        writeLine(entry)
    }

    /// Flushes and closes the recording file.
    /// - Throws: An error if the file cannot be synchronized.
    public func close() throws {
        try fileHandle.synchronize()
        fileHandle.closeFile()
    }

    // MARK: - Private

    private func writeLine(_ entry: SessionEntry<Message>) {
        guard let data = try? encoder.encode(entry) else { return }
        var line = data
        line.append(contentsOf: [UInt8(ascii: "\n")])
        fileHandle.write(line)
    }
}
