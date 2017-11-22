//
//  Region.swift
//  FlixDNS
//
//  Created by Enrico Ghirardi on 18/11/2017.
//  Copyright © 2017 Enrico Ghirardi. All rights reserved.
//

import Foundation

class Region: CustomStringConvertible, Equatable {
    var code: String
    
    init(code: String) {
        self.code = code
    }

    static func ==(lhs: Region, rhs: Region) -> Bool {
        return (lhs.code == rhs.code)
    }
    
    func countryName() -> String {
        if code == "XX" {
            return "Disabled"
        }
        if let name = (Locale.current as NSLocale).displayName(forKey: .countryCode, value: code) {
            return name
        } else {
            return "Unknown"
        }
    }
    
    var description: String {
        return "\(countryName()) with code: \(code)"
    }
}
