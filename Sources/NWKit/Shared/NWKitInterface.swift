//
//  NWKitInterface.swift
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
import SystemConfiguration

/// NWKit Interface
///
struct NWKitInterface {
    
    /// Attempts to find an NWInterface from a string describing it.
    ///
    /// - parameters:
    ///    - interfaceString: The string describing the interface. This may be either a name (e.g. "en1" or "lo0") or IP address (e.g. "10.0.0.1").
    ///
    /// - Returns: An optional `NWInterface`.
    ///
    internal static func interface(from interfaceString: String) -> NWInterface? {
        if let interface = IPv4Address(interfaceString)?.interface {
            return interface
        } else if let interface = IPv6Address(interfaceString)?.interface {
            return interface
        } else {
            let interfaces = SCNetworkInterfaceCopyAll() as? Array<SCNetworkInterface> ?? []
            let nwInterfaces = interfaces.compactMap { interface -> NWInterface? in
                guard let bsdName = SCNetworkInterfaceGetBSDName(interface) else { return nil }
                if let interface = IPv4Address("127.0.0.1%\(bsdName)")?.interface {
                    return interface
                } else if let interface = IPv6Address("::1%\(bsdName)")?.interface {
                    return interface
                }
                return nil
            }
            return nwInterfaces.first(where: { $0.name == interfaceString })
        }
    }
    
}
