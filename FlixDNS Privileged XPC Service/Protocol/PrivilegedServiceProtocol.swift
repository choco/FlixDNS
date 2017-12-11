//
//  PrivilegedServiceProtocol.swift
//  FlixDNS
//
//  Created by Enrico Ghirardi on 20/11/2017.
//  Copyright © 2017 Enrico Ghirardi. All rights reserved.
//

import Foundation

@objc(SmartDNSConfiguration) class SmartDNSConfiguration: NSObject, Codable, NSSecureCoding {
    
    static var supportsSecureCoding: Bool {
        get { return true }
    }
    
    private struct NSCoderKeys {
        static let revisionKey = "revision"
        static let DNSKey = "dns"
        static let domainsKey = "domains"
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(NSNumber(value: revision), forKey: NSCoderKeys.revisionKey)
        aCoder.encode(NSArray(array:DNS.map{NSString(string:$0)}), forKey: NSCoderKeys.DNSKey)
        aCoder.encode(NSArray(array:domains.map{NSString(string:$0)}), forKey: NSCoderKeys.domainsKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let revision = aDecoder.decodeObject(of: NSNumber.self, forKey: NSCoderKeys.revisionKey) as? UInt else {
            return nil
        }
        // Can't use the secure version because of Apple bug here, good job
        guard let DNS = aDecoder.decodeObject(forKey: NSCoderKeys.DNSKey) as? [String] else {
            return nil
        }
        guard let domains = aDecoder.decodeObject(forKey: NSCoderKeys.domainsKey) as? [String] else {
            return nil
        }
        self.init(revision: revision, DNS: DNS, domains: domains)
    }
    
    let revision: UInt
    let DNS: [String]
    let domains: [String]
    
    init(revision: UInt, DNS: [String], domains: [String]) {
        self.revision = revision
        self.DNS = DNS
        self.domains = domains
    }
}

struct PrivilegedHelperConstants {
    static let machServiceName = "me.choco.FlixDNS-Privileged-Helper"
}

// Protocol to list all functions the main application can call in the helper
@objc(PrivilegedHelperProtocol)
protocol PrivilegedHelperProtocol {
    func getVersion(reply: (String) -> Void)
    func getInstalledSmartDNSConfRevision(reply: (UInt) -> Void)
    func flushDNSCache(reply: @escaping (NSNumber, String) -> Void)
    func installSmartDNSConf(_ smartDNSConf: SmartDNSConfiguration, reply: (Bool, String) -> Void)
}
