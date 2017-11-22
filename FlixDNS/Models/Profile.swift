//
//  Profile.swift
//  FlixDNS
//
//  Created by Enrico Ghirardi on 18/11/2017.
//  Copyright © 2017 Enrico Ghirardi. All rights reserved.
//

import Foundation

struct Profile: CustomStringConvertible {
    var email: String
    var known: Bool
    var active: Bool
    var IP: String
    var dns: Bool
    var locked: Bool
    var status: String
    var ip_changed: Bool
    var reactivated: Bool
    var accepted: Bool
    var current: String
    var cc_disabled: Bool
    var country: String
    var expiresOn: String
    var dragon: Bool
    var old_dns: Bool
    
    var description: String {
        return """
        
        \(email): is known: \(known) active: \(active) and status: \(status)
        Is locked: \(locked) accepted: \(accepted) and is using correct DNS: \(dns)
        Current IP: \(IP) is registered in the system: \(!ip_changed)
        Current country: \(country) and selected region \(current)
        Captions are disabled: \(cc_disabled) and IP is reactivated: \(reactivated)
        
        """
    }
}
