//
//  NWKitUDPServerError.swift
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

/// NWKit UDP Server Error
///
/// Enumerates all possible `NWKitUDPServer` errors.
public enum NWKitUDPServerError: Error {
    
    /// The provided UDP port is invalid.
    case invalidPort(_ port: UInt16)
    
    /// The provided multicast group is invalid.
    case invalidMulticastGroup(_ multicastGroup: String)
    
    /// There are multiple errors.
    case multipleErrors(_ errors: [Error])
    
    /// An endpoint was not found.
    case noConnectionForEndpoint(_ endpoint: NWEndpoint)
    
}

/// NWKit UDP Server Error Extensions
///
/// `CustomStringConvertible` Conformance
extension NWKitUDPServerError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidPort(let port):
            return "The provided port \(port) is not valid."
        case .invalidMulticastGroup(let multicastGroup):
            return "The provided multicast group \(multicastGroup) is not valid."
        case .multipleErrors(let errors):
            return "There are multiple errors (\(errors.count))."
        case .noConnectionForEndpoint(let endpoint):
            return "A connection with endpoint \(endpoint) could not be found."
        }
    }
}

/// NWKit UDP Server Error Extensions
///
/// `LocalizedError` Conformance
extension NWKitUDPServerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidPort(let port):
            return NSLocalizedString(
                "The provided port \(port) is not valid.",
                comment: "Invalid Port"
            )
        case .invalidMulticastGroup(let multicastGroup):
            return NSLocalizedString(
                "The provided multicast group \(multicastGroup) is not valid.",
                comment: "Invalid Multicast Group"
            )
        case .multipleErrors(let errors):
            return NSLocalizedString(
                "There are multiple errors (\(errors.count)).",
                comment: "Multiple Errors"
            )
        case .noConnectionForEndpoint(let endpoint):
            return NSLocalizedString(
                "A connection with endpoint \(endpoint) could not be found.",
                comment: "No Connection"
            )
        }
    }
}
