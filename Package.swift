// swift-tools-version: 6.0
//
//  Package.swift
//  SwiftCLIKit
//
//  Created by Justin Purnell on 2026-04-10.
//

import PackageDescription

let package = Package(
    name: "SwiftCLIKit",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "SwiftCLIKit", targets: ["SwiftCLIKit"]),
    ],
    targets: [
        .target(
            name: "SwiftCLIKit"
        ),
        .testTarget(
            name: "SwiftCLIKitTests",
            dependencies: ["SwiftCLIKit"]
        ),
    ]
)
