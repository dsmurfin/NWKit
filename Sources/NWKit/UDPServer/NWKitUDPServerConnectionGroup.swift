//
//  NWKitUDPServerConnectionGroup.swift
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

/// NWKit UDP Server Connection Group
///
@available(iOS 14, macOS 11, *)
final internal class NWKitUDPServerConnectionGroup {
    
    /// The `NWConnectionGroup` associated with this server connection group.
    private let connectionGroup: NWConnectionGroup
    
    /// A unique identifier for the connection group.
    private let id: UUID
    
    /// A weak reference to the server which received this connection group.
    private weak var server: NWKitUDPServer?
    
    /// The remote endpoint associated with this connection group.
    var endpoint: NWEndpoint? {
        connectionGroup.descriptor.members.first
    }
    
    /// Initializes a new `NWKitUDPServerConnectionGroup` from an `NWConnectionGroup`.
    ///
    /// - parameters:
    ///    - connectionGroup: A new `NWConnectionGroup`.
    ///
    init(connectionGroup: NWConnectionGroup, server: NWKitUDPServer) {
        self.connectionGroup = connectionGroup
        self.id = UUID()
        self.server = server
    }
    
    /// Starts the connection, ready to receive data.
    ///
    /// - parameters:
    ///    - queue: The queue on which to receive connection group events.
    ///
    func start(onQueue queue: DispatchQueue) {
        guard let server else { return }
        self.receive(on: self.connectionGroup)
        connectionGroup.stateUpdateHandler = { (newState) in
            let connectionId = self.id
            let connectionGroup = self.connectionGroup
            switch (newState) {
            case .setup:
                #if DEBUG
                print("Connection Group: Setup: \(connectionId) \(connectionGroup)")
                #endif
            case .waiting(let error):
                #if DEBUG
                print("Connection Group: Waiting: \(connectionId) \(connectionGroup) \(error)")
                #endif
            case .ready:
                #if DEBUG
                print("Connection Group: Ready: \(connectionId) \(connectionGroup)")
                #endif
                server.addConnectionGroup(self)
            case .failed(let error):
                #if DEBUG
                print("Connection Group: Failed: \(connectionId) \(connectionGroup) \(error)")
                #endif
                server.removeConnectionGroup(self)
            case .cancelled:
                #if DEBUG
                print("Connection Group: Cancelled: \(connectionId) \(connectionGroup)")
                #endif
                server.removeConnectionGroup(self)
            default:
                break
            }
        }
        connectionGroup.start(queue: queue)
    }
    
    /// Cancels the connection group.
    func cancel() {
        connectionGroup.cancel()
    }
    
    /// Returns an optional `NWEndpoint.Host` for this `NWKitUDPServerConnectionGroup`.
    func host() -> NWEndpoint.Host? {
        hostPort()?.host
    }
    
    /// Returns an optional `NWEndpoint.Port` for this `NWKitUDPServerConnectionGroup`.
    func port() -> NWEndpoint.Port? {
        hostPort()?.port
    }
    
    /// Returns an optional `NWEndpoint.Host` and `NWEndPoint.Port` for this `NWKitUDPServerConnectionGroup`.
    func hostPort() -> (host: NWEndpoint.Host, port: NWEndpoint.Port)? {
        guard let endpoint else { return nil }
        switch endpoint {
        case .hostPort(let host, let port):
            return (host: host, port: port)
        default:
            return nil
        }
    }
    
    /// Handles receiving and processing messages for a connection group.
    ///
    /// - parameters:
    ///    - connectionGroup: The connection group for which to receive messages.
    ///
    private func receive(on connectionGroup: NWConnectionGroup) {
        connectionGroup.setReceiveHandler(maximumMessageSize: 1500, rejectOversizedMessages: true) { (message, content, isComplete) in
            guard let server = self.server else { return }
            guard isComplete, let content = content else {
                #if DEBUG
                print("Error: Received nil Data")
                #endif
                return
            }

            server._delegate?.server(server, receivedMessage: content, from: message.remoteEndpoint)
        }
    }
    
}

/// NWKit UDP Server Connection Group
///
/// Equatable Conformance.
@available(iOS 14, macOS 11, *)
extension NWKitUDPServerConnectionGroup: Equatable {
    static func == (lhs: NWKitUDPServerConnectionGroup, rhs: NWKitUDPServerConnectionGroup) -> Bool {
        lhs.id == rhs.id
    }
}

/// NWKit UDP Server Connection Group
///
/// Hashable Conformance.
@available(iOS 14, macOS 11, *)
extension NWKitUDPServerConnectionGroup: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

