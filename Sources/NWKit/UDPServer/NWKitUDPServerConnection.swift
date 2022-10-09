//
//  NWKitUDPServerConnection.swift
//
//  Copyright (c) 2022 Daniel Murfin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import Network

/// NWKit UDP Server Connection
///
@available(iOS 12, macOS 10.14, *)
final internal class NWKitUDPServerConnection {

    /// The `NWConnection` associated with this server connection.
    private let connection: NWConnection
    
    /// A unique identifier for the connection.
    private let id: UUID
    
    /// A weak reference to the server which received this connection.
    private weak var server: NWKitUDPServer?
    
    /// The remote endpoint associated with this connection.
    var endpoint: NWEndpoint {
        connection.endpoint
    }

    /// Initializes a new `NWKitUDPServerConnection` from an `NWConnection`.
    ///
    /// - parameters:
    ///    - connection: A new `NWConnection`.
    ///
    init(connection: NWConnection, server: NWKitUDPServer) {
        self.connection = connection
        self.id = UUID()
        self.server = server
    }
    
    /// Starts the connection, ready to receive data.
    ///
    /// - parameters:
    ///    - queue: The queue on which to receive connection events.
    ///
    func start(onQueue queue: DispatchQueue) {
        guard let server else { return }
        connection.stateUpdateHandler = { (newState) in
            let connectionId = self.id
            let connection = self.connection
            switch (newState) {
            case .setup:
                #if DEBUG
                print("Connection: Setup: \(connectionId) \(connection)")
                #endif
            case .waiting(let error):
                #if DEBUG
                print("Connection: Waiting: \(connectionId) \(connection) \(error)")
                #endif
            case .ready:
                #if DEBUG
                print("Connection: Ready: \(connectionId) \(connection)")
                #endif
                server.addConnection(self)
                self.receive(on: connection)
            case .failed(let error):
                #if DEBUG
                print("Connection: Failed: \(connectionId) \(connection) \(error)")
                #endif
                server.removeConnection(self)
            case .cancelled:
                #if DEBUG
                print("Connection: Cancelled: \(connectionId) \(connection)")
                server.removeConnection(self)
                #endif
            default:
                break
            }
        }
        connection.start(queue: queue)
    }
    
    /// Cancels the connection.
    func cancel() {
        connection.cancel()
    }
    
    /// Returns an optional `NWEndpoint.Host` for this `NWKitUDPServerConnection`.
    func host() -> NWEndpoint.Host? {
        hostPort()?.host
    }
    
    /// Returns an optional `NWEndpoint.Port` for this `NWKitUDPServerConnection`.
    func port() -> NWEndpoint.Port? {
        hostPort()?.port
    }
    
    /// Returns an optional `NWEndpoint.Host` and `NWEndPoint.Port` for this `NWKitUDPServerConnection`.
    func hostPort() -> (host: NWEndpoint.Host, port: NWEndpoint.Port)? {
        switch connection.endpoint {
        case .hostPort(let host, let port):
            return (host: host, port: port)
        default:
            return nil
        }
    }
    
    /// Handles receiving and processing messages for a connection.
    ///
    /// - parameters:
    ///    - connection: The connection for which to receive messages.
    ///
    private func receive(on connection: NWConnection) {
        connection.receiveMessage { (content, context, isComplete, error) in
            guard let server = self.server else { return }
            if let error = error {
                #if DEBUG
                print("Error: NWError received in \(#function) - \(error)")
                #endif
                return
            }
            guard isComplete, let content = content else {
                #if DEBUG
                print("Error: Received nil Data with context - \(String(describing: context))")
                #endif
                return
            }
            
            server._delegate?.server(server, receivedMessage: content, from: connection.endpoint)
            
            // ready to receive the next message
            if server._isListening {
                self.receive(on: connection)
            }
        }
    }
    
}

/// NWKit UDP Server Connection
///
/// Equatable Conformance.
extension NWKitUDPServerConnection: Equatable {
    static func == (lhs: NWKitUDPServerConnection, rhs: NWKitUDPServerConnection) -> Bool {
        lhs.id == rhs.id
    }
}

/// NWKit UDP Server Connection
///
/// Hashable Conformance.
extension NWKitUDPServerConnection: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
