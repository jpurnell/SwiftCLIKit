// AlternateScreenTests.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Testing
import Foundation
@testable import SwiftCLIKit

@Suite("AlternateScreen")
struct AlternateScreenTests {

    @Test("Init writes enter sequence containing ESC[?1049h")
    func initWritesEnterSequence() {
        let pipe = Pipe()
        let fd = pipe.fileHandleForWriting.fileDescriptor
        let _ = AlternateScreen(fileDescriptor: fd)
        pipe.fileHandleForWriting.closeFile()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        #expect(output.contains("\u{001B}[?1049h"))
    }

    @Test("isActive is true after init")
    func isActiveAfterInit() {
        let pipe = Pipe()
        let screen = AlternateScreen(fileDescriptor: pipe.fileHandleForWriting.fileDescriptor)
        #expect(screen.isActive == true)
    }

    @Test("Deinit writes leave sequence containing ESC[?1049l")
    func deinitWritesLeaveSequence() {
        let pipe = Pipe()
        let fd = pipe.fileHandleForWriting.fileDescriptor
        do {
            let _ = AlternateScreen(fileDescriptor: fd)
        }
        pipe.fileHandleForWriting.closeFile()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        #expect(output.contains("\u{001B}[?1049l"))
    }
}
