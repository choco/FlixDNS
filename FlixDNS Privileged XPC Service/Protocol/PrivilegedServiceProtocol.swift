//
//  PrivilegedServiceProtocol.swift
//  FlixDNS
//
//  Created by Enrico Ghirardi on 20/11/2017.
//  Copyright © 2017 Enrico Ghirardi. All rights reserved.
//

import Foundation

struct SmartDNSConfiguration: Codable {
    let revision: UInt
    let DNS: [String]
    let domains: [String]
}

struct PrivilegedHelperConstants {
    static let machServiceName = "me.choco.FlixDNS-Privileged-Helper"
    static let shutDownTime = 0.5
}

// Protocol to list all functions the main application can call in the helper
@objc(PrivilegedHelperProtocol)
protocol PrivilegedHelperProtocol {
    func getVersion(reply: (String) -> Void)
    func getInstalledSmartDNSConfRevision(reply: (UInt) -> Void)
    func flushDNSCache(reply: @escaping (NSNumber, String) -> Void)
    func installSmartDNSConf(revision: UInt, dns: [String], domains: [String], reply: (Bool, String) -> Void)
    func uninstallHelper(reply: (Bool, String) -> Void)
}
