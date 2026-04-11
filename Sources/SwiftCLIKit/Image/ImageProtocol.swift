// ImageProtocol.swift
// SwiftCLIKit
// Created by Justin Purnell on 2026-04-10.

import Foundation

/// Minimal pixel buffer holding RGBA data for image rendering.
///
/// Used by ``SixelEncoder`` and ``ASCIIArt`` which operate on raw pixel data
/// rather than compressed file bytes.
///
/// ```swift
/// // Create a 2x2 red image
/// let red: [UInt8] = [255, 0, 0, 255, 255, 0, 0, 255,
///                     255, 0, 0, 255, 255, 0, 0, 255]
/// let pixels = PixelData(bytes: red, width: 2, height: 2)
/// ```
public struct PixelData: Sendable, Equatable {
    /// Raw RGBA pixel bytes. Length must equal `width * height * 4`.
    public let bytes: [UInt8]
    /// Image width in pixels.
    public let width: Int
    /// Image height in pixels.
    public let height: Int

    /// Creates a pixel data buffer.
    /// - Parameters:
    ///   - bytes: RGBA pixel bytes. Count must equal `width * height * 4`.
    ///   - width: Image width in pixels. Must be non-negative.
    ///   - height: Image height in pixels. Must be non-negative.
    public init(bytes: [UInt8], width: Int, height: Int) {
        precondition(width >= 0, "Width must be non-negative")
        precondition(height >= 0, "Height must be non-negative")
        precondition(bytes.count == width * height * 4,
                     "Byte count (\(bytes.count)) must equal width * height * 4 (\(width * height * 4))")
        self.bytes = bytes
        self.width = width
        self.height = height
    }

    /// Access a single pixel's RGBA values.
    /// - Parameters:
    ///   - x: Horizontal pixel coordinate (0-based).
    ///   - y: Vertical pixel coordinate (0-based).
    /// - Returns: A tuple of (r, g, b, a) component values.
    public func pixel(x: Int, y: Int) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        precondition(x >= 0 && x < width, "x (\(x)) out of bounds [0, \(width))")
        precondition(y >= 0 && y < height, "y (\(y)) out of bounds [0, \(height))")
        let offset = (y * width + x) * 4
        return (bytes[offset], bytes[offset + 1], bytes[offset + 2], bytes[offset + 3])
    }
}
