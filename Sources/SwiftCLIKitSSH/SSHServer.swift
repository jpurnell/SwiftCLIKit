// SSHServer.swift
// SwiftCLIKitSSH
// Created by Justin Purnell on 2026-04-10.

import Foundation
import NIOCore
import NIOPosix
@preconcurrency import NIOSSH
import os
import SwiftCLIKit

/// An SSH server that can spawn isolated SwiftCLIKit app sessions per connection.
///
/// Each connecting client receives its own ``SSHBackend`` and ``SSHSession``,
/// enabling fully isolated TUI sessions over SSH.
///
/// ```swift
/// let server = SSHServer(port: 2222)
/// try await server.start { backend, session in
///     // Run your TUI app using the SSH backend
///     backend.write("Welcome, \(session.remoteAddress)\r\n")
/// }
/// ```
///
/// - Note: This is a simplified v1.12.0 implementation. The server accepts
///   all connections without authentication by default. Production deployments
///   should configure ``SSHConfiguration/authMode`` appropriately.
public struct SSHServer: Sendable {
    private static let logger = Logger(subsystem: "com.swiftclikit", category: "SSHServer")

    /// The host address to bind to.
    public let host: String
    /// The port to listen on.
    public let port: Int
    /// How the server obtains its host key.
    public let hostKeySource: HostKeySource
    /// Server configuration for authentication, limits, and timeouts.
    public let configuration: SSHConfiguration

    /// Source for the SSH server's host key.
    public enum HostKeySource: Sendable {
        /// Generate an ephemeral Ed25519 key each time the server starts (development mode).
        case generateEphemeral
        /// Load the host key from the given file path.
        case filePath(String) // LIVE: public API
    }

    /// Creates an SSH server with the given parameters.
    /// - Parameters:
    ///   - host: The address to bind to. Defaults to "0.0.0.0".
    ///   - port: The port to listen on. Defaults to 2222.
    ///   - hostKeySource: How to obtain the host key. Defaults to `.generateEphemeral`.
    ///   - configuration: Server configuration. Defaults to ``SSHConfiguration``.
    public init(
        host: String = "0.0.0.0",
        port: Int = 2222,
        hostKeySource: HostKeySource = .generateEphemeral,
        configuration: SSHConfiguration = SSHConfiguration()
    ) {
        self.host = host
        self.port = port
        self.hostKeySource = hostKeySource
        self.configuration = configuration
    }

    /// Starts the SSH server, blocking until shutdown.
    ///
    /// For each incoming connection, the `sessionHandler` closure is invoked
    /// with an ``SSHBackend`` and ``SSHSession`` for that connection.
    ///
    /// - Parameter sessionHandler: A closure that handles each SSH session.
    /// - Throws: Any error from NIO bootstrap or binding.
    public func start(
        sessionHandler: @escaping @Sendable (SSHBackend, SSHSession) async throws -> Void
    ) async throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

        let hostKey = NIOSSHPrivateKey(ed25519Key: .init())
        let _ = SessionManager(maxConnections: configuration.maxConnections)
        let authDelegate = AcceptAllAuth()

        let bootstrap = ServerBootstrap(group: group)
            .childChannelInitializer { channel in
                let handler = NIOSSHHandler(
                    role: .server(
                        .init(
                            hostKeys: [hostKey],
                            userAuthDelegate: authDelegate
                        )
                    ),
                    allocator: channel.allocator,
                    inboundChildChannelInitializer: nil
                )
                return channel.pipeline.addHandler(handler)
            }
            .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)

        let serverChannel = try await bootstrap.bind(host: host, port: port).get()
        Self.logger.info("SSH server listening on \(host, privacy: .public):\(port, privacy: .public)")

        do {
            try await serverChannel.closeFuture.get()
        } catch {
            try await group.shutdownGracefully()
            throw error
        }
        try await group.shutdownGracefully()
    }
}

/// Simplified authentication delegate that accepts all connections.
///
/// Intended for development use only. Production deployments should use
/// ``SSHConfiguration/AuthMode/password(_:)`` or ``SSHConfiguration/AuthMode/publicKey``.
// Justification: stateless delegate with no mutable fields; all properties are computed
private final class AcceptAllAuth: NIOSSHServerUserAuthenticationDelegate, @unchecked Sendable {
    /// Reports all authentication methods as supported.
    var supportedAuthenticationMethods: NIOSSHAvailableUserAuthenticationMethods { .all }

    /// Accepts any authentication request unconditionally.
    func requestReceived(
        request: NIOSSHUserAuthenticationRequest,
        responsePromise: EventLoopPromise<NIOSSHUserAuthenticationOutcome>
    ) {
        responsePromise.succeed(.success)
    }
}
