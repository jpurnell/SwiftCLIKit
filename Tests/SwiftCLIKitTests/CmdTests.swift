// CmdTests.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Testing
import Foundation
@testable import SwiftCLIKit

@Suite("Cmd")
struct CmdTests {

    @Test("Cmd.none constructs without crashing")
    func cmdNoneExists() {
        let cmd = Cmd<Int>.none
        // Verify it is the none kind
        if case .none = cmd.kind {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected .none kind")
        }
    }

    @Test("Cmd.quit constructs without crashing")
    func cmdQuitExists() {
        let cmd = Cmd<Int>.quit
        if case .quit = cmd.kind {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected .quit kind")
        }
    }

    @Test("Cmd.batch with empty array does not crash")
    func cmdBatchEmpty() {
        let cmd = Cmd<Int>.batch([])
        if case .batch(let cmds) = cmd.kind {
            #expect(cmds.isEmpty)
        } else {
            #expect(Bool(false), "Expected .batch kind")
        }
    }

    @Test("Cmd.task constructs without crashing")
    func cmdTaskCreation() {
        let cmd = Cmd<Int>.task { 42 }
        if case .task = cmd.kind {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected .task kind")
        }
    }
}
