// KeyReader.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Foundation

/// Decodes raw bytes from a ``RawTerminal`` into structured ``Key`` values,
/// handling UTF-8 multi-byte sequences and CSI escape codes.
///
/// ```swift
/// let pipe = Pipe()
/// pipe.fileHandleForWriting.write(Data([0x1B, 0x5B, 0x41]))  // arrow-up
/// pipe.fileHandleForWriting.closeFile()
/// let reader = KeyReader(terminal: RawTerminal(fileDescriptor: pipe.fileHandleForReading.fileDescriptor))
/// let key = reader.readKey()  // .arrowUp
/// ```
public struct KeyReader: Sendable {
    private let terminal: RawTerminal

    /// Creates a key reader that pulls bytes from the given raw terminal.
    /// - Parameter terminal: The ``RawTerminal`` to read from.
    public init(terminal: RawTerminal) { self.terminal = terminal }

    /// Reads and decodes the next key press, blocking until a byte is available.
    /// - Returns: The decoded ``Key``, or `nil` on EOF.
    public func readKey() -> Key? {
        guard let byte = terminal.readByte() else { return nil }

        switch byte {
        case 0x00:
            return .unknown(0x00)
        case 0x01:
            return .ctrlA
        case 0x03:
            return .ctrlC
        case 0x04:
            return .ctrlD
        case 0x05:
            return .ctrlE
        case 0x09:
            return .tab
        case 0x0A, 0x0D:
            return .enter
        case 0x0B:
            return .ctrlK
        case 0x0C:
            return .ctrlL
        case 0x15:
            return .ctrlU
        case 0x17:
            return .ctrlW
        case 0x1B:
            return readEscapeSequence()
        case 0x7F:
            return .backspace
        default:
            if byte < 0x80 {
                return .character(Character(UnicodeScalar(byte)))
            }
            return readUTF8(firstByte: byte)
        }
    }

    private func readEscapeSequence() -> Key {
        guard let next = terminal.readByte() else { return .escape }

        guard next == 0x5B else {
            // ESC followed by something other than '[' — return bare escape
            return .escape
        }

        // CSI sequence: ESC [ <params> <final>
        // Collect parameter bytes (0x20-0x3F range) until we get a final byte (0x40-0x7E)
        var params: [UInt8] = []
        while true {
            guard let paramByte = terminal.readByte() else { return .escape }
            if paramByte >= 0x40 && paramByte <= 0x7E {
                // Final byte
                return mapCSI(params: params, finalByte: paramByte)
            }
            params.append(paramByte)
        }
    }

    private func mapCSI(params: [UInt8], finalByte: UInt8) -> Key {
        switch finalByte {
        case 0x41: // A
            return .arrowUp
        case 0x42: // B
            return .arrowDown
        case 0x43: // C
            return .arrowRight
        case 0x44: // D
            return .arrowLeft
        case 0x48: // H
            return .home
        case 0x46: // F
            return .end
        case 0x7E: // ~
            // Check params for specific sequences
            if params == [0x33] { // "3~" = delete
                return .delete
            }
            return .unknown(finalByte)
        default:
            return .unknown(finalByte)
        }
    }

    private func readUTF8(firstByte: UInt8) -> Key {
        let continuationCount: Int
        var value: UInt32

        switch firstByte {
        case 0xC0...0xDF:
            continuationCount = 1
            value = UInt32(firstByte & 0x1F)
        case 0xE0...0xEF:
            continuationCount = 2
            value = UInt32(firstByte & 0x0F)
        case 0xF0...0xF7:
            continuationCount = 3
            value = UInt32(firstByte & 0x07)
        default:
            return .unknown(firstByte)
        }

        for _ in 0..<continuationCount {
            guard let cont = terminal.readByte() else { return .unknown(firstByte) }
            guard cont & 0xC0 == 0x80 else { return .unknown(firstByte) }
            value = (value << 6) | UInt32(cont & 0x3F)
        }

        guard let scalar = Unicode.Scalar(value) else { return .unknown(firstByte) }
        return .character(Character(scalar))
    }
}
