// LocalizationTests.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import XCTest
@testable import SwiftCLIKit

final class LocalizationTests: XCTestCase {

    // MARK: - LocaleManager Tests

    /// Localized "en" returns the English string.
    func testLocalizedEnglishReturnsEnglishString() {
        let manager = LocaleManager(
            locale: "en",
            strings: ["greeting": ["en": "Hello", "ja": "こんにちは"]]
        )
        XCTAssertEqual(manager.localized("greeting"), "Hello")
    }

    /// SetLocale "ja" returns the Japanese string.
    func testSetLocaleJapaneseReturnsJapaneseString() {
        var manager = LocaleManager(
            locale: "en",
            strings: ["greeting": ["en": "Hello", "ja": "こんにちは"]]
        )
        manager.setLocale("ja")
        XCTAssertEqual(manager.localized("greeting"), "こんにちは")
    }

    /// Missing key returns the key itself as fallback.
    func testMissingKeyReturnsKeyAsFallback() {
        let manager = LocaleManager(locale: "en")
        XCTAssertEqual(manager.localized("nonexistent_key"), "nonexistent_key")
    }

    /// Pluralized count=1 returns "one" form, count=5 returns "other" form.
    func testPluralizedEnglish() {
        let manager = LocaleManager(
            locale: "en",
            pluralStrings: [
                "items_count": [
                    "en": [
                        .one: "{count} item",
                        .other: "{count} items",
                    ]
                ]
            ]
        )
        XCTAssertEqual(manager.localized("items_count", count: 1), "1 item")
        XCTAssertEqual(manager.localized("items_count", count: 5), "5 items")
        XCTAssertEqual(manager.localized("items_count", count: 0), "0 items")
    }

    /// Load from JSON file produces a working locale manager.
    func testLoadFromJSONFile() throws {
        let json = """
        {
            "greeting": { "en": "Hello", "es": "Hola" },
            "items_count": {
                "en": { "one": "{count} item", "other": "{count} items" }
            }
        }
        """

        let tempDir = NSTemporaryDirectory() + "SwiftCLIKitL10n_\(UUID().uuidString)/"
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        let path = tempDir + "strings.json"
        try json.write(toFile: path, atomically: true, encoding: .utf8)

        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        var manager = try LocaleManager.load(from: path)
        XCTAssertEqual(manager.localized("greeting"), "Hello")

        manager.setLocale("es")
        XCTAssertEqual(manager.localized("greeting"), "Hola")

        manager.setLocale("en")
        XCTAssertEqual(manager.localized("items_count", count: 1), "1 item")
        XCTAssertEqual(manager.localized("items_count", count: 3), "3 items")
    }

    /// TerminalFormatter truncates number output to maxWidth.
    func testTerminalFormatterTruncatesToMaxWidth() {
        let wide = TerminalFormatter.formatNumber(1_234_567.89, locale: "en", maxWidth: 20)
        XCTAssertLessThanOrEqual(wide.count, 20)
        XCTAssertTrue(wide.contains("1"))

        let narrow = TerminalFormatter.formatNumber(1_234_567.89, locale: "en", maxWidth: 5)
        XCTAssertLessThanOrEqual(narrow.count, 5)
    }

    // MARK: - PluralRule Tests

    /// English plural rules: 1=one, everything else=other.
    func testPluralRuleEnglish() {
        XCTAssertEqual(PluralRule.category(for: 1, locale: "en"), .one)
        XCTAssertEqual(PluralRule.category(for: 0, locale: "en"), .other)
        XCTAssertEqual(PluralRule.category(for: 5, locale: "en"), .other)
        XCTAssertEqual(PluralRule.category(for: 21, locale: "en"), .other)
    }

    /// Arabic plural rules cover all six categories.
    func testPluralRuleArabic() {
        XCTAssertEqual(PluralRule.category(for: 0, locale: "ar"), .zero)
        XCTAssertEqual(PluralRule.category(for: 1, locale: "ar"), .one)
        XCTAssertEqual(PluralRule.category(for: 2, locale: "ar"), .two)
        XCTAssertEqual(PluralRule.category(for: 6, locale: "ar"), .few)
        XCTAssertEqual(PluralRule.category(for: 11, locale: "ar"), .many)
        XCTAssertEqual(PluralRule.category(for: 100, locale: "ar"), .other)
    }

    /// Japanese always returns .other (no plural forms).
    func testPluralRuleJapanese() {
        XCTAssertEqual(PluralRule.category(for: 0, locale: "ja"), .other)
        XCTAssertEqual(PluralRule.category(for: 1, locale: "ja"), .other)
        XCTAssertEqual(PluralRule.category(for: 5, locale: "ja"), .other)
    }

    /// TerminalFormatter date respects maxWidth.
    func testTerminalFormatterDateRespectsMaxWidth() {
        let date = Date(timeIntervalSince1970: 0)  // 1970-01-01
        let narrow = TerminalFormatter.formatDate(date, locale: "en", maxWidth: 4)
        XCTAssertLessThanOrEqual(narrow.count, 4)
    }
}
