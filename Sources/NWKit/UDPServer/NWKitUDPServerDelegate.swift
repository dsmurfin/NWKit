//
//  NWKitUDPServerDelegate.swift
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

/// NWKit UDP Server Delegate
///
public protocol NWKitUDPServerDelegate: AnyObject {
    
    /// Called when a `NWKitUDPServer` has started listening.
    ///
    /// - Parameters:
    ///    - server: The `NWKitUDPServer` which has started listening.
    ///
    func serverStartedListening(_ server: NWKitUDPServer)
    
    /// Called when a `NWKitUDPServer` has stopped listening.
    ///
    /// This will be called whenever a server stops listening even if it is an intended.
    /// When the server stops listening as a result of an error, this will be returned.
    ///
    /// - Parameters:
    ///    - server: The `NWKitUDPServer` which has stopped listening.
    ///    - error: An optional `Error` which occured.
    ///
    func serverStoppedListening(_ server: NWKitUDPServer, withError error: Error?)
    
    /// Called when a message has been received from a `NWKitUDPServer`.
    ///
    /// - Parameters:
    ///    - server: The `NWKitUDPServer` which received the message.
    ///    - message: The message as `Data`.
    ///    - endpoint: An optional remote `NWEndpoint` from which the message originated.
    ///
    func server(_ server: NWKitUDPServer, receivedMessage message: Data, from endpoint: NWEndpoint?)

}
