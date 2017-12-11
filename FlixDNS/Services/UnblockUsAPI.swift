//
//  UnblockUsAPI.swift
//  FlixDNS
//
//  Created by Enrico Ghirardi on 17/11/2017.
//  Copyright © 2017 Enrico Ghirardi. All rights reserved.
//

import Foundation

class UnblockUsAPI {
    var auth_email: String!
    
    private let BASE_URL         = "https://check.unblock-us.com/"
    private let STATUS_ENDPOINT  = "get-status.js"
    private let COUNTRY_ENDPOINT = "set-country.js"
    
    static let SmartDNSConf = SmartDNSConfiguration(
        revision: 1,
        DNS: [
            "64.145.73.5",
            "209.107.219.5"
        ],
        domains: [
            "hulu.com",
            "hbo.com",
            "hbogo.com",
            "netflix.com",
            "nflximg.net",
            "nflxvideo.net",
            "nflxext.com",
            "nflxso.net",
            "unblock-us.com"
        ])

    init(auth_email: String) {
        self.auth_email = auth_email
    }

    func fetchProfile(_ success: @escaping (Profile) -> Void, failed: @escaping () -> Void) {
        unblockUsCall(endpoint: STATUS_ENDPOINT, parse_data: { (data,failed) in
            if let profile = self.profileFromJSONData(data, failed: failed) {
                success(profile)
            }
        }, failed: {
            failed()
        })
    }
    
    func fetchAvailableRegions(_ success: @escaping ([Region]) -> Void, failed: @escaping () -> Void) {
        unblockUsCall(endpoint: COUNTRY_ENDPOINT, parse_data: { (data,failed) in
            if let regions = self.regionsFromJSONData(data, failed: failed) {
                success(regions)
            }
        }, failed: {
            failed()
        })
    }
    
    func setRegion(_ region: Region, success: @escaping (Bool) -> Void, failed: @escaping () -> Void) {
        let cc = region.code == "GB" ? "UK" : region.code
        unblockUsCall(endpoint: COUNTRY_ENDPOINT, params: ["code=\(cc)"], parse_data: { (data,failed) in
            if let res_region = self.currentRegionFromJSONData(data, failed: failed) {
                success(region == res_region)
            }
        }, failed: {
            failed()
        })
    }
    
    func getCurrentRegion(_ success: @escaping (Region) -> Void, failed: @escaping () -> Void) {
        unblockUsCall(endpoint: COUNTRY_ENDPOINT, parse_data: { (data,failed) in
            if let region = self.currentRegionFromJSONData(data,failed: failed) {
                success(region)
            }
        }, failed: {
            failed()
        })
    }
    
    func updateIP(_ success: @escaping (Bool) -> Void, failed: @escaping () -> Void) {
        unblockUsCall(endpoint: STATUS_ENDPOINT, params: ["reactivate=1"], parse_data: { (data,failed) in
            if let profile = self.profileFromJSONData(data,failed: failed) {
                success(profile.reactivated)
            }
        }, failed: {
            failed()
        })
    }
    
    private func currentRegionFromJSONData(_ data: Data, failed: () -> Void) -> Region? {
        let myrange : Range<Data.Index> = 1..<data.count-1
        let correct_data = data.subdata(in: myrange)
        typealias JSONDict = [String:AnyObject]
        let json : JSONDict
        
        do {
            json = try JSONSerialization.jsonObject(with: correct_data, options: []) as! JSONDict
        } catch {
            NSLog("JSON parsing failed: \(error)")
            return nil
        }
        
        let cc = json["current"] as! String

        return (cc == "UK") ? Region(code: "GB") : Region(code: cc)
    }
    
    private func regionsFromJSONData(_ data: Data, failed: () -> Void) -> [Region]? {
        if(data.count < 2) {
            NSLog("Malformed response")
            return nil
        }
        let myrange : Range<Data.Index> = 1..<data.count-1
        let correct_data = data.subdata(in: myrange)
        typealias JSONDict = [String:AnyObject]
        let json : JSONDict
        
        do {
            json = try JSONSerialization.jsonObject(with: correct_data, options: []) as! JSONDict
        } catch {
            NSLog("JSON parsing failed: \(error)")
            return nil
        }
        
        let regions_ccs = json["list"] as! [String]
        
        return regions_ccs.map { ($0 == "UK") ? Region(code: "GB") : Region(code: $0) }
    }

    private func profileFromJSONData(_ data: Data, failed: () -> Void) -> Profile? {
        if(data.count < 6) {
            NSLog("Malformed response")
            return nil
        }
        let myrange : Range<Data.Index> = 5..<data.count-2
        let correct_data = data.subdata(in: myrange)
        typealias JSONDict = [String:AnyObject]
        let json : JSONDict
        
        do {
            json = try JSONSerialization.jsonObject(with: correct_data, options: []) as! JSONDict
        } catch {
            NSLog("JSON parsing failed: \(error)")
            return nil
        }
        
        let profile = Profile(
            email: json["email"] as! String,
            known: json["is_known"] as! Bool,
            active: json["is_active"] as! Bool,
            IP: json["ip"] as! String,
            dns: json["our_dns"] as! Bool,
            locked: json["locked"] as! Bool,
            status: json["status"] as! String,
            ip_changed: json["ip_changed"] as! Bool,
            reactivated: json["reactivated"] as! Bool,
            accepted: json["accepted"] as! Bool,
            current: json["current"] as! String,
            cc_disabled: json["cc_disabled"] as! Bool,
            country: json["country"] as! String,
            expiresOn: json["expiresOn"] as! String,
            dragon: json["dragon"] as! Bool,
            old_dns: json["old_dns"] as! Bool
        )
        
        return profile
    }
    
    private func unblockUsCall(endpoint: String, params: [String] = [], parse_data: @escaping (Data, (() -> Void)) -> Void, failed: @escaping () -> Void) {
        let session = URLSession.shared
        let auth_cookie = "_stored_email_=\(auth_email.addingPercentEncoding(withAllowedCharacters:.urlHostAllowed)!)"
        var url = "\(BASE_URL)\(endpoint)"
        if !params.isEmpty {
            let params_escaped = params.map{ $0.addingPercentEncoding(withAllowedCharacters:.urlHostAllowed)! }
            url += "?" + params_escaped.joined(separator: "&")
        }
        var request = URLRequest.init(url: URL(string: url)!)
        request.addValue(auth_cookie, forHTTPHeaderField: "Cookie")

        let task = session.dataTask(with: request) { data, response, err in
            // first check for a hard error
            if let error = err {
                NSLog("Unblock-us api error: \(error)")
                failed()
            }
            
            // then check the response code
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200: // all good!
                    parse_data(data!, failed)
                case 401: // unauthorized
                    NSLog("Unblock-us api returned an 'unauthorized' response. Did you set your API key?")
                    failed()
                default:
                    NSLog("Unblock-us api returned response: %d %@", httpResponse.statusCode, HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
                    failed()
                }
            }
        }
        task.resume()
    }
}

