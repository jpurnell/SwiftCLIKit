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
        .library(name: "SwiftCLIKitSSH", targets: ["SwiftCLIKitSSH"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio-ssh.git", from: "0.9.0"),
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
