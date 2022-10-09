//
//  NWKitUDPServer.swift
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

/// NWKit UDP Server
///
@available(iOS 13, macOS 10.15, *)
public class NWKitUDPServer {
    
    /// The established connections.
    private var connections: Set<NWKitUDPServerConnection> = []
    
    /// The established connection groups.
    private var _connectionGroups: Any? = nil
    @available(iOS 14, macOS 11, *)
    private var connectionGroups: Set<NWKitUDPServerConnectionGroup> {
        get {
            if _connectionGroups == nil {
                _connectionGroups = Set<NWKitUDPServerConnectionGroup>()
            }
            return _connectionGroups as! Set<NWKitUDPServerConnectionGroup>
        } set {
            _connectionGroups = newValue
        }
    }
    
    /// The listener detects and listens to UDP data streams.
    private var listener: NWListener?
    
    /// The `DispatchQueue` on which to receive connection events.
    private let queue: DispatchQueue
    
    /// An optional `UDPServerDelegate`which should receive notifications from the server.
    ///
    /// Set the delegate to `nil` to stop receiving notifications from the server.
    public var delegate: NWKitUDPServerDelegate? {
        get { queue.sync { _delegate } }
        set { queue.sync { _delegate = newValue } }
    }
    
    /// An optional delegate which should receive notifications from the server.
    internal private (set) weak var _delegate: NWKitUDPServerDelegate?
    
    /// An optional interface on which to listen, this may be a name (e.g. "en1" or "lo0"), IP address (e.g. "10.0.0.1") or `nil`.
    /// If the value is `nil`, the server will listen on all interfaces.
    ///
    /// Setting this variable will stop the server listening.
    public var interface: String? {
        didSet {
            guard interface != oldValue else { return}
            stopListening()
        }
    }
    
    /// The UDP port on which to listen.
    ///
    /// Setting this variable will stop the server listening.
    public var port: UInt16 {
        didSet {
            guard port != oldValue else { return }
            stopListening()
        }
    }
    
    /// The optional multicast groups that should be joined after the server starts listening.
    /// If this is `nil`, the server functions as a unicast listener.
    private var multicastGroups: Set<NWEndpoint.Host>?
    
    /// The multicast groups that have successfully been joined.
    public var joinedMulticastGroups: [String] {
        get {
            let joinedMulticastGroups = queue.sync { _joinedMulticastGroups }
            return joinedMulticastGroups.compactMap { $0.formattedString }
        }
    }
    
    /// The multicast groups that have successfully been joined (private).
    private var _joinedMulticastGroups: Set<NWEndpoint.Host> = []
    
    /// Whether the server is currently listening for UDP messages.
    public private(set) var isListening: Bool {
        get { queue.sync { _isListening } }
        set { queue.sync { _isListening = newValue } }
    }

    /// Whether the server is currently listening for UDP messages (private).
    internal private (set) var _isListening: Bool = false
    
    // MARK: Public API
    
    /// Initializes the server with a port, and optionally an interface and multicast groups.
    ///
    /// After initializing the server, call `startListening` to begin listening using the configuration provided.
    ///
    /// - parameters:
    ///    - interface: Optional: An optional interface on which to listen. This may be either a name (e.g. "en1" or "lo0"), IP address (e.g. "10.0.0.1") or `nil`.
    ///    - port: The UDP port on which to listen.
    ///    - delegateQueue: Optional: An optional serial `DispatchQueue` on which to receive delegate notifications.
    ///
    public init(interface: String?, port: UInt16, delegateQueue: DispatchQueue? = nil) {
        self.queue = delegateQueue ?? DispatchQueue(label: "UDPServer-\(UUID().uuidString)")
        self.interface = interface
        self.port = port
    }
    
    /// Initializes the server with a port, and optionally an interface and multicast groups.
    ///
    /// If the server is initialized with `multicastGroups` set to `nil`, it will start as a unicast listener.
    /// If multicast groups are added later, the server will stop and need to be started again.
    ///
    /// After initializing the server, call `startListening` to begin listening using the configuration provided.
    ///
    /// - parameters:
    ///    - interface: Optional: An optional interface on which to listen. This may be either a name (e.g. "en1" or "lo0"), IP address (e.g. "10.0.0.1") or `nil`.
    ///    - port: The UDP port on which to listen.
    ///    - multicastGroups: Optional: An optional array of multicast groups to subscribe to.
    ///    - delegateQueue: Optional: An optional serial `DispatchQueue` on which to receive delegate notifications.
    ///
    @available(iOS 14, macOS 11, *)
    public init(interface: String?, port: UInt16, multicastGroups: [String]? = nil, delegateQueue: DispatchQueue? = nil) {
        self.queue = delegateQueue ?? DispatchQueue(label: "UDPServer-\(UUID().uuidString)")
        self.interface = interface
        self.port = port
        if let multicastGroups {
            self.multicastGroups = Set(multicastGroups.compactMap { multicastGroup in
                let host: NWEndpoint.Host?
                if let address = IPv4Address(multicastGroup), address.isMulticast {
                    host = NWEndpoint.Host(multicastGroup)
                } else if let address = IPv6Address(multicastGroup), address.isMulticast  {
                    host = NWEndpoint.Host(multicastGroup)
                } else {
                    host = nil
                }
                return host
            })
        }
    }
    
    deinit {
        stopListening()
    }
    
    /// Starts listening for messages.
    ///
    /// This may fail if the configuration provided is invalid.
    ///
    /// - throws: A `NWKitUDPServerError`or `NWError`.
    ///
    public func startListening() throws {
        if let listener {
            listener.start(queue: self.queue)
        } else {
            try configureServer()
            listener?.start(queue: self.queue)
        }
    }
    
    /// Stops listening for messages.
    ///
    /// If `clearingMulticast` is set to `true`, the multicast group subscriptions will also be cleared.
    ///
    /// - parameters:
    ///    - clearingMulticast: Whether multicast groups should be reset.
    ///
    public func stopListening(clearingMulticast: Bool = false) {
        guard isListening else { return }
        if #available(iOS 14, macOS 11, *) {
            let joinedMulticastGroups = queue.sync { _joinedMulticastGroups }
            joinedMulticastGroups.forEach { self.leaveMulticastGroup($0, preserveGroup: !clearingMulticast) }
        }
        listener?.cancel()
    }
    
    /// Attempts to join the multicast group provided.
    ///
    /// If this server was initialized with `multicastGroups` set to `nil` and a valid multicast group
    /// is provided the server will stop and must be started again.
    ///
    /// - parameters:
    ///    - multicastGroup: The multicast group to join.
    ///
    /// - throws: A `NWKitUDPServerError`or `NWError`.
    ///
    @available(iOS 14, macOS 11, *)
    public func joinMulticastGroup(_ multicastGroup: String) throws {
        let host: NWEndpoint.Host?
        if let address = IPv4Address(multicastGroup), address.isMulticast {
            host = NWEndpoint.Host(multicastGroup)
        } else if let address = IPv6Address(multicastGroup), address.isMulticast  {
            host = NWEndpoint.Host(multicastGroup)
        } else {
            host = nil
        }
        
        guard let host else {
            throw NWKitUDPServerError.invalidMulticastGroup(multicastGroup)
        }
        
        // if multicastGroups is nil we should stop listening
        let multicastGroups = queue.sync { self.multicastGroups }
        if multicastGroups != nil {
            try queue.sync {
                try joinMulticastGroup(host)
            }
        } else {
            queue.sync {
                self.multicastGroups = Set([host])
            }
            stopListening()
        }
    }
    
    /// Attempts to join the multicast group provided.
    ///
    /// - parameters:
    ///    - multicastGroup: The multicast group to join.
    ///
    /// - throws: A `NWKitUDPServerError`or `NWError`.
    ///
    @available(iOS 14, macOS 11, *)
    private func joinMulticastGroup(_ multicastGroup: NWEndpoint.Host) throws {
        guard !self._joinedMulticastGroups.contains(multicastGroup) else { return }
        multicastGroups?.insert(multicastGroup)
        
        guard let port = NWEndpoint.Port(rawValue: self.port) else {
            throw NWKitUDPServerError.invalidPort(self.port)
        }
        let endpoint: NWEndpoint = .hostPort(host: multicastGroup, port: port)
        
        let params: NWParameters = .udp
        
        // application data can be included with the protocol handshake
        // almost always desirable for UDP
        params.allowFastOpen = true
        
        // equivalent to port reuse
        params.allowLocalEndpointReuse = true
        
        if let interface, let nwInterface = NWKitInterface.interface(from: interface) {
            params.requiredInterface = nwInterface
        }

        let multicastGroup = try NWMulticastGroup(for: [endpoint], disableUnicast: false)
        let newConnectionGroup = NWConnectionGroup(with: multicastGroup, using: params)
        let connectionGroup = NWKitUDPServerConnectionGroup(connectionGroup: newConnectionGroup, server: self)
        connectionGroup.start(onQueue: self.queue)
    }
    
    /// Attempts to leave the multicast group provided.
    ///
    /// If a valid multicast group is provided, and this is the last multicast group joined,
    /// the server will stop, switch to unicast and must be started again.
    ///
    /// - parameters:
    ///    - multicastGroup: The multicast group to leave.
    ///
    /// - throws: A `NWKitUDPServerError`or `NWError`.
    ///
    @available(iOS 14, macOS 11, *)
    public func leaveMulticastGroup(_ multicastGroup: String) throws {
        let host: NWEndpoint.Host?
        if let address = IPv4Address(multicastGroup), address.isMulticast {
            host = NWEndpoint.Host(multicastGroup)
        } else if let address = IPv6Address(multicastGroup), address.isMulticast  {
            host = NWEndpoint.Host(multicastGroup)
        } else {
            host = nil
        }
        
        guard let host else {
            throw NWKitUDPServerError.invalidMulticastGroup(multicastGroup)
        }
        
        queue.sync {
            leaveMulticastGroup(host, preserveGroup: false)
        }
    }
    
    /// Attempts to leave the multicast group provided.
    ///
    /// If `preserve` is set to `true`, the group will be rejoined if the servers starts listening again.
    ///
    /// - parameters:
    ///    - multicastGroup: The multicast group to leave.
    ///    - preserve: Whether to preserve knowledge of the group.
    ///
    @available(iOS 14, macOS 11, *)
    private func leaveMulticastGroup(_ multicastGroup: NWEndpoint.Host, preserveGroup: Bool) {
        guard self._joinedMulticastGroups.contains(multicastGroup) else { return }
        if !preserveGroup {
            self.multicastGroups?.remove(multicastGroup)
            
            // converts the server to unicast
            if let multicastGroups, multicastGroups.isEmpty {
                self.multicastGroups = nil
            }
        }
        guard _isListening else { return }

        if let connectionGroup = self.connectionGroups.first(where: { $0.host() == multicastGroup }) {
            connectionGroup.cancel()
        }
    }
    
    /// Configures whether to allow local addresses and ports to be reused across connections.
    ///
    /// This is roughly equivalent to port reuse in BSD sockets.
    ///
    /// - parameters:
    ///    - allowReuse: Whether endpoint reuse is permitted.
    ///
    func allowLocalEndpointReuse(_ allowReuse: Bool) {
        listener?.parameters.allowLocalEndpointReuse = allowReuse
    }
    
    // MARK: Private
    
    /// Configures the server with either an `NWListener` for unicast,
    /// or array of`NWConnectionGroup` if multicast groups have been provided.
    ///
    /// - throws: An error of type `NWKitUDPServerError` or `NWError`.
    ///
    private func configureServer() throws {
        if #available(iOS 14, macOS 11, *) {
            let multicastGroups = queue.sync { self.multicastGroups }
            
            if let multicastGroups {
                // throw early if the port is invalid
                guard NWEndpoint.Port(rawValue: self.port) != nil else {
                    throw NWKitUDPServerError.invalidPort(self.port)
                }
                
                var errors: [Error] = []
                multicastGroups.forEach {
                    do {
                        try self.joinMulticastGroup($0)
                    } catch {
                        errors.append(error)
                    }
                }
                
                if errors.count > 1 {
                    throw NWKitUDPServerError.multipleErrors(errors)
                } else if let error = errors.first {
                    throw error
                }
            } else {
                try configureListener()
            }
        } else {
            try configureListener()
        }
    }
    
    /// Configures the listener, ready to start receiving data.
    ///
    /// - throws: An error of type `NWKitUDPServerError` or `NWError`.
    ///
    private func configureListener() throws {
        guard let port = NWEndpoint.Port(rawValue: self.port) else {
            throw NWKitUDPServerError.invalidPort(self.port)
        }
        
        let params: NWParameters = .udp
        
        // application data can be included with the protocol handshake
        // almost always desirable for UDP
        params.allowFastOpen = true
        
        // equivalent to port reuse
        params.allowLocalEndpointReuse = true
        
        if let interface = self.interface, let nwInterface = NWKitInterface.interface(from: interface) {
            params.requiredInterface = nwInterface
        }
        
        self.listener = try NWListener(using: params, on: port)
        
        // handle listener state changes
        self.listener?.stateUpdateHandler = { newState in
            switch newState {
            case .setup:
                #if DEBUG
                print("Setup: port \(port)")
                #endif
            case .waiting(let error):
                #if DEBUG
                print("Waiting: port \(port) \(error)")
                #endif
            case .ready:
                #if DEBUG
                print("Ready: port \(port)")
                #endif
                self.listenerListening(true)
            case .failed(let error):
                #if DEBUG
                print("Failed: port \(port) \(error)")
                #endif
                self.listenerListening(false)
            case .cancelled:
                #if DEBUG
                print("Cancelled: port \(port)")
                #endif
                self.connections.forEach {
                    // cancelling a connection also removes it
                    // from the list of observed connections
                    $0.cancel()
                }
                self.listener = nil
                self.listenerListening(false)
            default:
                break
            }
        }
        
        // handle new connections
        self.listener?.newConnectionHandler = { [weak self] (newConnection) in
            if let strongSelf = self {
                let connection = NWKitUDPServerConnection(connection: newConnection, server: strongSelf)
                connection.start(onQueue: strongSelf.queue)
            }
        }
    }
    
    /// Updates the listening state of this server, and notifies the delegate.
    ///
    /// - parameters:
    ///    - listening: Whether the server is listening.
    ///    - error: Optional: An optional error which occured (defaults to `nil`).
    ///
    private func listenerListening(_ listening: Bool, error: Error? = nil) {
        guard self._isListening != listening else { return }
        self._isListening = listening
        
        if listening {
            _delegate?.serverStartedListening(self)
        } else {
            _delegate?.serverStoppedListening(self, withError: error)
        }
    }
    
}

/// UDP Server Extension
///
/// Connection notifications.
extension NWKitUDPServer {
    
    /// Notifies the `NWKitUDPServer` that a new `NWKitUDPServerConnection` should be added.
    ///
    /// - parameters:
    ///    - connection: The `NWKitUDPServerConnection` to add.
    ///
    internal func addConnection(_ connection: NWKitUDPServerConnection) {
        connections.insert(connection)
    }
    
    /// Notifies the `NWKitUDPServer` that a `NWKitUDPServerConnection` should be removed.
    ///
    /// - parameters:
    ///    - connection: The `NWKitUDPServerConnection` to remove.
    ///
    internal func removeConnection(_ connection: NWKitUDPServerConnection) {
        connections.remove(connection)
    }
    
    /// Notifies the `NWKitUDPServer` that a new `NWKitUDPServerConnectionGroup` should be added.
    ///
    /// - parameters:
    ///    - connectionGroup: The `NWKitUDPServerConnectionGroup` to add.
    ///
    @available(iOS 14, macOS 11, *)
    internal func addConnectionGroup(_ connectionGroup: NWKitUDPServerConnectionGroup) {
        connectionGroups.insert(connectionGroup)
        if let host = connectionGroup.host() {
            _joinedMulticastGroups.insert(host)
        }
        listenerListening(true)
    }
    
    /// Notifies the `NWKitUDPServer` that a `NWKitUDPServerConnectionGroup` should be removed.
    ///
    /// - parameters:
    ///    - connectionGroup: The `NWKitUDPServerConnectionGroup` to remove.
    ///
    @available(iOS 14, macOS 11, *)
    internal func removeConnectionGroup(_ connectionGroup: NWKitUDPServerConnectionGroup) {
        connectionGroups.remove(connectionGroup)
        if let host = connectionGroup.host() {
            _joinedMulticastGroups.remove(host)
        }
        if connectionGroups.isEmpty {
            listenerListening(false)
        }
    }
    
}
