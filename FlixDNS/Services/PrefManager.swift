//
//  PrefManager.swift
//  FlixDNS
//
//  Created by Enrico Ghirardi on 18/11/2017.
//  Copyright © 2017 Enrico Ghirardi. All rights reserved.
//

import Foundation

struct Keys {
    static let accountEmail = "accountEmail"
    static let startAtLogin = "startAtLogin"
}


class PrefManager {
    static let shared = PrefManager()
    
    private init() {
        registerFactoryDefaults()
    }
    
    let userDefaults = UserDefaults.standard
    
    private func registerFactoryDefaults() {
        let factoryDefaults = [
            Keys.accountEmail: String(""),
            Keys.startAtLogin: Bool(false),
            ] as [String : Any]
        
        userDefaults.register(defaults: factoryDefaults)
    }
    
    func synchronize() {
        userDefaults.synchronize()
    }
    
    func reset() {
        userDefaults.removeObject(forKey: Keys.accountEmail)
        userDefaults.removeObject(forKey: Keys.startAtLogin)
        
        synchronize()
    }
}
