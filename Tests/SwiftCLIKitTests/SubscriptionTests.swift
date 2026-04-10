// SubscriptionTests.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Testing
import Foundation
@testable import SwiftCLIKit

@Suite("Subscription")
struct SubscriptionTests {

    @Test("Timer subscription constructs with correct key")
    func timerCreation() {
        let sub = Subscription<Int>.timer(key: "tick", every: .seconds(1), message: { 0 })
        #expect(sub.key == "tick")
        if case .timer = sub.kind {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected .timer kind")
        }
    }

    @Test("Subscription.none constructs without crashing")
    func noneExists() {
        let sub = Subscription<Int>.none
        #expect(sub.key == "")
        if case .none = sub.kind {
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected .none kind")
        }
    }
}
