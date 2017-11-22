//
//  PrivilegedServiceProtocol.swift
//  FlixDNS
//
//  Created by Enrico Ghirardi on 20/11/2017.
//  Copyright © 2017 Enrico Ghirardi. All rights reserved.
//

import Foundation

struct PrivilegedHelperConstants {
    static let machServiceName = "me.choco.FlixDNS-Privileged-Helper"
}

// Protocol to list all functions the main application can call in the helper
@objc(PrivilegedHelperProtocol)
protocol PrivilegedHelperProtocol {
    func getVersion(reply: (String) -> Void)
    func flushDNSCache(reply: @escaping (NSNumber, String) -> Void)
    func setCustomDNS(dns: [String], for domains: [String], reply: (Bool, [String: String]) -> Void)
}
