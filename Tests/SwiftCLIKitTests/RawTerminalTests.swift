// RawTerminalTests.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Testing
import Foundation
@testable import SwiftCLIKit

@Suite("RawTerminal")
struct RawTerminalTests {

    @Test("Pipe round-trip: write two bytes, read them back in order")
    func pipeRoundTrip() {
        let pipe = Pipe()
        let terminal = RawTerminal(fileDescriptor: pipe.fileHandleForReading.fileDescriptor)
        let data = Data([0x41, 0x42])
        pipe.fileHandleForWriting.write(data)
        pipe.fileHandleForWriting.closeFile()

        let first = terminal.readByte()
        let second = terminal.readByte()
        #expect(first == 0x41)
        #expect(second == 0x42)
    }

    @Test("EOF on closed pipe returns nil")
    func eofOnClosedPipe() {
        let pipe = Pipe()
        pipe.fileHandleForWriting.closeFile()
        let terminal = RawTerminal(fileDescriptor: pipe.fileHandleForReading.fileDescriptor)

        let result = terminal.readByte()
        #expect(result == nil)
    }

    @Test("isRawMode is true on Darwin after initialization")
    func isRawModeFlag() {
        let pipe = Pipe()
        let terminal = RawTerminal(fileDescriptor: pipe.fileHandleForReading.fileDescriptor)

        #expect(terminal.isRawMode == true)
    }
}
