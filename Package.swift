// swift-tools-version: 6.0
// Pinned: remote deploy target (roseclub.org) runs Swift 6.0.3
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
        .library(name: "SwiftCLIKitSSH", targets: ["SwiftCLIKitSSH"]),
        .executable(name: "swiftclikit-examples", targets: ["swiftclikit-examples"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio-ssh.git", from: "0.9.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3"),
    ],
    targets: [
        .target(
            name: "SwiftCLIKit"
        ),
        .target(
            name: "SwiftCLIKitSSH",
            dependencies: [
                "SwiftCLIKit",
                .product(name: "NIOSSH", package: "swift-nio-ssh"),
            ]
        ),
        .executableTarget(
            name: "swiftclikit-examples",
            dependencies: ["SwiftCLIKit"],
            path: "Sources/swiftclikit-examples"
        ),
        .testTarget(
            name: "SwiftCLIKitTests",
            dependencies: ["SwiftCLIKit"]
        ),
        .testTarget(
            name: "SwiftCLIKitSSHTests",
            dependencies: ["SwiftCLIKitSSH"]
        ),
    ]
)
